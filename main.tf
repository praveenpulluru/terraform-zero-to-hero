import { Component, Inject, Input, OnInit, OnDestroy, ChangeDetectionStrategy, ChangeDetectorRef, EventEmitter, Output } from '@angular/core';
import moment from 'moment';
import { Subject, Subscription } from 'rxjs';

import { RoomService } from '../../providers/room/room.service';
import { Room } from '../../providers/room/room.model';
import { LocationMaxBookingDetails, ROOM_CONF } from '../../providers/room/room.interface';
import { DateTimeService } from "../../providers/date-time.service";
import { CommunicationService } from '../../providers/communication/communication.service';
import { debounceTime } from 'rxjs/operators';



@Component({
  selector: 'vz-sh-scheduler',
  templateUrl: 'scheduler.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush

})

export class SchedulerComponent implements OnInit, OnDestroy {
  private disableDateChangeOnChange: boolean;
  private setScheduleSubscription: Subscription;
  public calendarDateErrorMessage: string = '';


  @Input() timePicker: string;
  @Input() setSchedule: Subject<any>;
  @Output() calendarDateValidityChanged = new EventEmitter<boolean>();

  hasTimeSlotBooked: boolean;
  updateDayCalendarByDate: Subject<any>;
  calendarDate: string;
  public allLocationMaxBookingDays: any = {};
  public maxScheduleDay: number | null = null;
  private isNavigatingDate = false;
  private nextDayClick$ = new Subject<void>();
  private prevDayClick$ = new Subject<void>();
  private clickSubscription: Subscription = new Subscription();

  constructor(public roomService: RoomService, public room: Room, private comms: CommunicationService,
    private cd: ChangeDetectorRef,
    @Inject(ROOM_CONF) private roomConf: any, private dateTimeService: DateTimeService) {

    this.updateDayCalendarByDate = new Subject<any>();
    this.disableDateChangeOnChange = false;
    this.hasTimeSlotBooked = false;
    this.calendarDate = this.room.getCurrentDayCalendar().date;
  }

  ngOnInit() {
    //initialization
    this.setScheduleSubscription = this.setSchedule.subscribe({
      next: () => {
        this.cd.markForCheck();
        this.cd.detectChanges();
      }
    });

    this.clickSubscription.add(
      this.nextDayClick$.pipe(debounceTime(500)).subscribe(() => {
        this.setSchedulerToPrevNextDay(true);
      })
    );

    this.clickSubscription.add(
      this.prevDayClick$.pipe(debounceTime(500)).subscribe(() => {
        this.setSchedulerToPrevNextDay(false);
      })
    );

    this.roomService.fetchMaxBookingDaysDetails().subscribe({
      next: (maxBookingDaysForLocation: LocationMaxBookingDetails[]) => {
        this.allLocationMaxBookingDays = maxBookingDaysForLocation;

        const roomDetails = this.room.getDetails();
        const locationId = parseInt(roomDetails.campusId);
        const resourceGroupId = roomDetails.resourceGroupId;

        const maxDays = this.getMaxBookingDaysFromResource(locationId, resourceGroupId);
        this.maxScheduleDay = maxDays ?? 90;

        this.calendarDate = this.room.getCurrentDayCalendar().date;
        this.updateScheduleByDate(this.calendarDate);

        this.calendarDateValidityChanged.emit(this.isDateWithinAllowedRange(this.calendarDate));
        this.cd.markForCheck();
        this.cd.detectChanges();
      },
      error: (err) => {
        console.error('Failed to fetch max booking days details:', err);
        this.maxScheduleDay = 90;
      }
    });
  }

  ngOnDestroy() {
    this.clickSubscription.unsubscribe();
    if (this.setScheduleSubscription) {
      this.setScheduleSubscription.unsubscribe();
    }

  }

  onNextDayClick() {
    this.nextDayClick$.next();
  }

  onPrevDayClick() {
    this.prevDayClick$.next();
  }

  disableDateChange(event) {

    this.hasTimeSlotBooked = event;
  }

  /*
    disable date change
   */
  isDateChangeDisabled(): boolean {
    return this.timePicker === 'true' && ((this.hasTimeSlotBooked || this.disableDateChangeOnChange) && this.isDateWithinAllowedRange(this.calendarDate));

  }
  /*
    when selecting a calendar date, the scheduler full day schedules will be updated via retrieving the data from service
   */

  updateScheduleByDate(date: string, callback?: () => void) {
  this.calendarDateErrorMessage = '';

  if (!this.isDateWithinAllowedRange(date)) {
    this.calendarDateErrorMessage = `The selected date is outside the allowed booking range. 
      You can only book within ${this.maxScheduleDay} days from today.`;
    this.calendarDateValidityChanged.emit(false);
    callback?.();
    return;
  }

  this.calendarDateValidityChanged.emit(true);
  this.disableDateChangeOnChange = true;

  // Do not assign calendarDate here — wait for API result
  this.getSchedulesByDate(date, callback);
  this.formInteraction();
}

  isDateWithinAllowedRange(date: string): boolean {
    if (this.maxScheduleDay === null) return true;
    const selected = moment(date).startOf('day');
    const min = moment().startOf('day');
    const max = moment().add(this.maxScheduleDay, 'days').startOf('day');
    return selected.isSameOrAfter(min) && selected.isSameOrBefore(max);
  }

  /*
   update scheduler data from service
   */
  private getSchedulesByDate(date: string, callback?: () => void) {
  const selectedDate = moment(date);

  this.roomService.getRoomScheduleByDate(
    this.room.getId(),
    selectedDate.format(DateTimeService.DATE_TIME_FORMAT.YEAR_MONTH_DAY)
  ).subscribe(
    schedules => {
      this.room.setCurrentDayCalendar({
        date,
        fullDaySchedule: schedules.fullDaySchedule
      });

      this.updateDayCalendarByDate.next(schedules);

      // Sync only after data is ready
      this.calendarDate = date;
      this.disableDateChangeOnChange = false;

      this.cd.markForCheck();
      this.cd.detectChanges();

      callback?.();
    },
    error => {
      this.room.showOfflinePage('Something went wrong, Please try again later');
      callback?.();
    }
  );
}

  /*
    change scheduler to prev or next day from current selected Date
   */
  setSchedulerToPrevNextDay(isNext: boolean) {
  if (this.isNavigatingDate || this.isDateChangeDisabled()) return;

  this.isNavigatingDate = true;

  const currentSelectedDate = moment(this.room.getCurrentDayCalendar().date);
  const selectedDate = isNext
    ? moment(currentSelectedDate).add(1, 'day')
    : moment(currentSelectedDate).subtract(1, 'day');

  const newDateStr = this.dateTimeService.getFormattedDateString(selectedDate, true);

  this.updateScheduleByDate(newDateStr, () => {
    // Only update calendarDate after update finishes
    this.calendarDate = newDateStr;
    this.isNavigatingDate = false;
  });

  this.formInteraction();
}


  getMinScheduleDate(): any {
    return moment();
  }

  getMaxScheduleDate(): string {
    return moment().add(this.maxScheduleDay, 'day').format('YYYY-MM-DD');
  }

  isMaxScheduleDate(): boolean {
    const currentDate = moment(this.room.getCurrentDayCalendar().date).startOf('day');
    const maxDate = moment().add(this.maxScheduleDay, 'days').startOf('day');

    return currentDate.isSame(maxDate, 'day');
  }

  getMoment(date: string) {
    return moment(date);
  }

  private formInteraction() {
    this.comms.sendMessage('scheduleFormTouched')
  }


  private getMaxBookingDaysFromResource(locationId: number, resourceGroupId: number): number | null {
    for (const location of this.allLocationMaxBookingDays) {
      if (location.locationId === locationId) {
        for (const group of location.resourceGroups) {
          if (group.resourceGroup === resourceGroupId) {
            return group.maxAdvancedBookingDays;
          }
        }
      }
    }
    return null;
  }

}



<div id="schedule">

  <ion-grid *ngIf="timePicker === 'true'" style="padding: 1em 0;">
    <ion-row class="pagination-prev-next scheduler-row">

      <ion-col class="col-prev" *ngIf="room.getDetails().allowFutureReservation" col-3>
        <button ion-button *ngIf="!room.isToday()" [disabled]="isDateChangeDisabled()" class="button-link prev"
          (click)="onPrevDayClick()">Prev day</button>
      </ion-col>


      <ion-col col-6 class="menu">

         <ion-item *ngIf="calendarDateErrorMessage">
              <p style="color: red; font-size: 1.4rem;">
                {{ calendarDateErrorMessage }}
              </p>
            </ion-item>

        <ion-item style="font-size: 1.5em;" *ngIf="!room.getDetails().allowFutureReservation">
          <ion-label>Schedule for today, <span class="calendar-icon">{{getMoment(room.getCurrentDayCalendar().date) |
              vzdatetimeformat: 'ddd ll'}}</span>
          </ion-label>
        </ion-item>

        <ion-item style="font-size: 1.5em;" *ngIf="room.getDetails().allowFutureReservation && maxScheduleDay != null">
          <ion-label>Schedule for&nbsp;<span *ngIf="room.isToday()">today,&nbsp;</span></ion-label>
          <ion-datetime displayFormat="DDD MMM D, YYYY" pickerFormat="MMM DD YYYY" cancelText="Cancel" doneText="Select"
            min="{{getMinScheduleDate() | vzdatetimeformat: 'YYYY-MM-DD'}}" max="{{getMaxScheduleDate()}}"
            [(ngModel)]="calendarDate" [disabled]="isDateChangeDisabled()"
            (ionChange)="updateScheduleByDate(calendarDate)" class="color-link calendar-icon">
          </ion-datetime>
        </ion-item>
      </ion-col>

      <ion-col class="col-nxt" *ngIf="room.getDetails().allowFutureReservation" col-3>
        <button ion-button *ngIf="!isMaxScheduleDate()" [disabled]="isDateChangeDisabled()" class="button-link"
          (click)="onNextDayClick()">Next day</button>
      </ion-col>
    </ion-row>
  </ion-grid>
  <vz-sh-scheduler-day-calendar timePicker="{{timePicker}}" [setSchedule]="setSchedule"
    [getHomeRoom]="roomService.getHomeRoomUpdate()" [getCurrentDateTime]="roomService.getCurrentDateTime()"
    [updateFullDayScheduleByDate]="updateDayCalendarByDate"
    (timeSlotBooked)="disableDateChange($event)"></vz-sh-scheduler-day-calendar>
</div>
