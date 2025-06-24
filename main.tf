import { Component, OnInit, ViewChild } from '@angular/core';
import { ToastrService } from 'ngx-toastr';
import {
  NgbPanelChangeEvent,
  NgbAccordion,
  NgbCalendar,
  NgbModal,
} from '@ng-bootstrap/ng-bootstrap';
import { HttpErrorResponse } from '@angular/common/http';
import { LoggedInUserDetailsService } from 'src/app/services/loggedIn-user.service';
import { BuildingInfoService } from 'src/app/services/building-info-service';
import { LoaderService } from 'src/app/loader/loader.service';
import { AppConstantsProvider } from 'src/app/providers/app-constants.provider';
import { SpaceTypeByGroup } from 'src/app/model/spaceTypeByGroup';
import { ObservableService } from 'src/app/services/observable-service';
import { BuildingResponseModal } from 'src/app/model/building-response';

import { ConfirmationDialogService } from 'src/app/modal/confirmation-modal-popup/confirmation-dialog.service';
// import { FeatureAddActionType } from 'src/app/enums/building-add-action-type.enum';

import { Router } from '@angular/router';
import { AppFeatureResponse } from 'src/app/interface/common.interface';
import { HelperService } from 'src/app/services/helper.service';
import { UserService } from 'src/app/services/user-service';

// import { feature } from 'src/app/pipes/features.pipe';
import { FeatureComm } from 'src/app/model/feature-comm.model';
import { RoleNames } from 'src/app/enums/roleNameDetails.enum';
import { FormBuilder, FormGroup, Validators } from '@angular/forms';
export enum FeatureAddActionType {
  ADD,
  CANCEL_ADD,
}

export interface Banner {
  id: number;
  title: string;
  description: string;
}

@Component({
  selector: 'app-app-feature',
  templateUrl: './app-feature.component.html',
  styleUrls: ['./app-feature.component.scss'],
})
export class AppFeatureComponent implements OnInit {
  @ViewChild('acc', { static: false }) accordion: NgbAccordion;
  public FeatureAddActionType = FeatureAddActionType;
  public featureAddActionType: FeatureAddActionType =
    FeatureAddActionType.CANCEL_ADD;
  public tzNames: any;
  public isEditClicked: boolean = false;
  public selecteddResourceGroupArray: any = [];
  public minDate = this.calendar.getToday();
  public featureName = '';
  public featureDescription = '';
  public addFeatureObj: FeatureComm = new FeatureComm();
  public editFeatureObj: FeatureComm = new FeatureComm();
  public displayNoDataFound: boolean = false;
  public getDisabledData: boolean = false;
  public addFloorName: string = '';
  public floorName: string = '';
  public floorStatus: boolean;
  public addResourceName: string = '';
  public addResouceSelectedGroup: any = [];
  public addResourceCheckinStatus: boolean = false;
  public addResourceStatus: boolean = false;
  public addResourceSelectedFeatures: any = [];
  public userAccessBuildings: any = [];
  public filteredFeatureData: any = [];
  public showNoDataMsg = false;
  public selectedBuildingFloorData: any = [];
  public featureDetails: any = [];
  public searchTerm: string = '';
  public selectedSpaceType: SpaceTypeByGroup;
  public spaceTypeDetails: SpaceTypeByGroup[] = [];
  public pageLimit = 15;
  public pager: any = [];
  public startIndex: number = 1;
  public selectedPage = 1;
  public qrCodeFileName = 'qrCode';
  public buildingIdsSelected: Array<number> = [];
  public resourceName: string = '';
  public resourceDetails: any = [];
  public selectedResourceGroup: any;
  public selectedFeatures: any = [];
  public featuresList: any = [];
  public resourceStatus: boolean = false;
  public checkInStatus: boolean = false;
  public showAddResourceContainer: boolean = false;
  public showAddFloorContainer: boolean = false;
  public selectedLocation: any = [];
  activeBuildingIds: any = [];
  activeFloorIds: any = [];
  public countryList: any;
  public statesList: any;
  public cityList: any;
  public base64OfImageToBeUploaded: any;
  public imageToBeUploaded: File;
  public addFeatureClicked: boolean = false;
  public userRoleName: any;

  bannerForm: FormGroup;
  bannerList: Banner[] = [];
  isEditingBanner = false;
  editingBannerId: number | null = null;
  isBannerSaving: boolean = false;
  isBannerDeleting: boolean = false;

  @ViewChild('bannerModal', {static
    :false
  }) bannerModalTemplate: any;

  constructor(
    private fb: FormBuilder,
    private modalService: NgbModal,
    private buildingInfoService: BuildingInfoService,
    private router: Router,
    private toastr: ToastrService,
    private loader: LoaderService,
    public observableService: ObservableService,
    public appConstanstProvider: AppConstantsProvider,
    public confirmationDialogService: ConfirmationDialogService,
    public loggedInUserDetailsService: LoggedInUserDetailsService,
    public userService: UserService,
    private calendar: NgbCalendar,
    private helperService: HelperService
  ) {
    this.userRoleName = RoleNames;
    this.bannerForm = this.fb.group({
      title: ['', [Validators.required, Validators.maxLength(100)]],
      description: ['', [Validators.required, Validators.maxLength(500)]]
    });
  }
  public editorConfig={
    toolbar:[
      [   'bold','italic','underline'],
      [   {list:'ordered'},{list:'bullet'}]
    ]
  };

  ngOnInit() {
    if (this.loggedInUserDetailsService.getLoggedInUserDetails()) {
      this.fetchAllFeaturesComDetails();
    } else {
      this.router.navigate(['']);
    }
    this.fetchBanners();
  }

  fetchUserAccessBuildings() {
    if (this.loggedInUserDetailsService.getLoggedInUserDetails()) {
      this.userAccessBuildings =
        this.loggedInUserDetailsService.getLoggedInUserDetails().locationAccesses;
      this.featureDetails = this.userAccessBuildings;
      this.updateBuildingsAndSpaceTypes();
    }
  }

  getPaginatorData() {
    this.pager = [];
    let pages = Math.ceil(this.featureDetails.length / this.pageLimit);
    for (var i = 0; i < pages; i++) {
      this.pager.push(i + 1);
    }
    this.setPageContent(1);
  }

  setPageContent(page) {
    this.isEditClicked = false;
    this.selectedBuildingFloorData = [];
    this.activeFloorIds = [];
    this.activeBuildingIds = [];
    this.selectedPage = page;
    let startIndex = (page - 1) * this.pageLimit;
    let endIndex = page * this.pageLimit;
    this.filteredFeatureData = this.featureDetails.slice(startIndex, endIndex);
    this.filteredFeatureData.sort((a, b) => a.title.localeCompare(b.title));
  }

  updateBuildingsAndSpaceTypes() {
    this.displayNoDataFound = false;
    this.isEditClicked = false;
    this.searchTerm = '';
    if (!this.getDisabledData) {
      this.featureDetails = this.userAccessBuildings.filter((data) => {
        if (data.enabled === true) {
          return data;
        }
      });
    } else {
      this.featureDetails = this.userAccessBuildings;
    }
    this.getPaginatorData();
  }

  panelStatusChanged($event: NgbPanelChangeEvent) {
    $event.preventDefault();
  }

  showAddFeature(e) {
    this.addFeatureClicked = true;
    this.showNoDataMsg = false;
    this.featureAddActionType = FeatureAddActionType.ADD;
    this.clearUploadedImage();
    this.closeOtherPanel(null, null, e);
  }

  onClickFeatureComm() {
    this.observableService.updateCurrentpage('appFeatureComm');
    this.router.navigate(['/appFeatureComm'], { skipLocationChange: true });
  }
  /**
   * Floor relted function
   */
  closeOtherPanel(selectedBuildingDetail, selectedFloorDetail, e) {
    this.activeBuildingIds = [];
    this.activeFloorIds = [];
    this.cancelAddResource();
    this.cancelAddFloor();
  }

  addAppFeature() {
    this.addFeatureClicked = false;
    if (
      !this.addFeatureObj.title &&
      !this.addFeatureObj.description &&
      !this.addFeatureObj.expiryDate
    ) {
      this.toastr.error(
        '',
        AppConstantsProvider.ERROR_MSG_CONSTANS.FIELDS_REQUIRED,
        AppConstantsProvider.TOASTR_CONFIG
      );
      return;
    }
    if (!this.addFeatureObj.title) {
      this.toastr.error(
        '',
        AppConstantsProvider.ERROR_MSG_CONSTANS.FEATURE_NAME_REQUIRED,
        AppConstantsProvider.TOASTR_CONFIG
      );
      return;
    }
    if (!this.addFeatureObj.description) {
      this.toastr.error(
        '',
        AppConstantsProvider.ERROR_MSG_CONSTANS.FEATURE_DESCRIPTION_REQUIRED,
        AppConstantsProvider.TOASTR_CONFIG
      );
      return;
    }
    if (!this.addFeatureObj.expiryDate) {
      this.toastr.error(
        '',
        AppConstantsProvider.ERROR_MSG_CONSTANS.FEATURE_EXPIRY_DATE_REQUIRED,
        AppConstantsProvider.TOASTR_CONFIG
      );
      return;
    }
    if (this.imageToBeUploaded && !this.isFileSizeValid()) {
      this.toastr.error(
        '',
        AppConstantsProvider.ERROR_MSG_CONSTANS.UPLOAD_IMAGE_SIZE_MEMORY,
        AppConstantsProvider.TOASTR_CONFIG
      );
      return;
    }

    let reqObj = {
      title: this.addFeatureObj.title,
      description: this.addFeatureObj.description,
      expiryDate:
        this.helperService.formatJsonToDateString(
          this.addFeatureObj.expiryDate
        ) + ' 23:59:59',
      timeZone: this.helperService.timeZone,
      featuredImg: this.base64OfImageToBeUploaded,
    };
    this.loader.showLoader();
    this.buildingInfoService.addAppFeature(reqObj).subscribe(
      (response: AppFeatureResponse) => {
        if (response.success) {
          this.loader.hideLoader();
          this.resetAddFeatureValues();
          this.featureAddActionType = FeatureAddActionType.CANCEL_ADD;
          this.toastr.success(
            '',
            response.message,
            AppConstantsProvider.TOASTR_CONFIG
          );
          this.fetchAllFeaturesComDetails();
        } else {
          this.loader.hideLoader();
          this.toastr.error(
            '',
            AppConstantsProvider.ERROR_MSG_CONSTANS.ERROR_ADDING_BUILDING,
            AppConstantsProvider.TOASTR_CONFIG
          );
        }
      },
      (error) => {
        this.loader.hideLoader();
        this.helperService.handleHttpErrorResponse(
          error,
          AppConstantsProvider.ERROR_MSG_CONSTANS.UNABLE_TO_ADD_BUILDING
        );
      }
    );
  }

  showAddFloor() {
    this.activeFloorIds = [];
    this.showAddFloorContainer = true;
    this.addFloorName = '';
    this.floorStatus = false;
  }

  cancelAddFloor() {
    this.resetAddFloorValues();
    this.showAddFloorContainer = false;
  }
  resetAddFloorValues() {
    this.addFloorName = '';
    this.floorStatus = true;
  }

  cancelAddFeature() {
    this.addFeatureClicked = false;
    if (this.filteredFeatureData.length === 0) {
      this.showNoDataMsg = true;
    }
    this.resetAddFeatureValues();
    this.featureAddActionType = FeatureAddActionType.CANCEL_ADD;
  }
  cancelAddResource() {
    this.resetAddResourceValues();
    this.showAddResourceContainer = false;
  }
  onAddResourceClicked() {
    this.showAddResourceContainer = true;
    this.addResourceName = '';
    this.addResourceSelectedFeatures = [];
    this.addResouceSelectedGroup = {};
    this.addResourceStatus = false;
    this.addResourceCheckinStatus = false;
  }

  resetAddResourceValues() {
    this.addResourceName = '';
    this.addResourceSelectedFeatures = '';
    this.addResouceSelectedGroup = [];
    this.addResourceStatus = false;
    this.addResourceCheckinStatus = false;
  }

  /**
   * Reset flags
   */
  resetAddFeatureValues() {
    this.addFeatureObj = new FeatureComm();
  }

  fetchAllFeaturesComDetails() {
    this.loader.showLoader();
    this.buildingInfoService.getAppFeaturesAll().subscribe(
      (response: any[]) => {
        this.loader.hideLoader();
        if (response && response.length > 0) {
          this.featureDetails = response;
          this.filteredFeatureData = response;
          this.showNoDataMsg =
            this.filteredFeatureData.length === 0 ? true : false;
        } else {
          this.featureDetails = [];
          this.filteredFeatureData = [];
          this.showNoDataMsg = true;
          this.loader.hideLoader();
          // this.toastr.error('', AppConstantsProvider.ERROR_MSG_CONSTANS.ERROR_FETCHING_FEATURES_DETAILS, AppConstantsProvider.TOASTR_CONFIG);
        }
      },
      (error: HttpErrorResponse) => {
        this.loader.hideLoader();
        this.featureDetails = [];
        this.filteredFeatureData = [];
        this.showNoDataMsg = true;
        this.helperService.handleHttpErrorResponse(
          error,
          AppConstantsProvider.ERROR_MSG_CONSTANS.UNABLE_TO_FETCH_FEATURES
        );
      }
    );
  }

  filterFeatureDetails() {
    this.filteredFeatureData = [];
    this.featureAddActionType = FeatureAddActionType.CANCEL_ADD;
    this.filteredFeatureData = this.featureDetails;
    this.searchTerm = this.searchTerm.toLowerCase();
    this.getPaginatorData();
    if (this.searchTerm.length > 0 && this.searchTerm.trim() !== '') {
      this.filteredFeatureData = this.featureDetails.filter((data) => {
        return data['title'].toLowerCase().includes(this.searchTerm);
      });
    }

    this.showNoDataMsg = this.filteredFeatureData.length === 0 ? true : false;
  }

  onEditFeatureIconClick(featureDetails: any, $event) {
    let expiryDate = this.helperService.changeDateDsiplayFormat(
      featureDetails.expiryDate
    );
    let expiryDateFormated = expiryDate.split('-');
    $event.stopPropagation();
    this.isEditClicked = true;
    this.filteredFeatureData.filter((featureData) => {
      featureData.editBuilding = false;
    });
    featureDetails.editBuilding = !featureDetails.editBuilding;
    this.editFeatureObj.title = featureDetails.title;
    this.editFeatureObj.description = featureDetails.description;
    this.editFeatureObj.featuredImg = featureDetails.featuredImg;
    this.base64OfImageToBeUploaded = featureDetails.featuredImg;
    this.editFeatureObj.expiryDate = {
      year: parseInt(expiryDateFormated[2], 0),
      month: parseInt(expiryDateFormated[0], 0),
      day: parseInt(expiryDateFormated[1], 0),
    };
  }

  onUpdateFeatureCancel(buildingData: BuildingResponseModal, $event) {
    $event.stopPropagation();
    this.isEditClicked = false;
    buildingData.editBuilding = !buildingData.editBuilding;
    this.activeBuildingIds = [];
    this.activeFloorIds = [];
    this.floorName = '';
    this.floorStatus = false;
    this.filteredFeatureData = this.featureDetails;
    this.searchTerm = '';
  }

  onUpdateFeatureClicked(buildingData: BuildingResponseModal) {
    if (
      !this.editFeatureObj.title &&
      !this.editFeatureObj.description &&
      !this.editFeatureObj.expiryDate
    ) {
      this.toastr.error(
        '',
        AppConstantsProvider.ERROR_MSG_CONSTANS.FIELDS_REQUIRED,
        AppConstantsProvider.TOASTR_CONFIG
      );
      return;
    }
    if (!this.editFeatureObj.title) {
      this.toastr.error(
        '',
        AppConstantsProvider.ERROR_MSG_CONSTANS.FEATURE_NAME_REQUIRED,
        AppConstantsProvider.TOASTR_CONFIG
      );
      return;
    }
    if (!this.editFeatureObj.description) {
      this.toastr.error(
        '',
        AppConstantsProvider.ERROR_MSG_CONSTANS.FEATURE_DESCRIPTION_REQUIRED,
        AppConstantsProvider.TOASTR_CONFIG
      );
      return;
    }
    if (!this.editFeatureObj.expiryDate) {
      this.toastr.error(
        '',
        AppConstantsProvider.ERROR_MSG_CONSTANS.FEATURE_EXPIRY_DATE_REQUIRED,
        AppConstantsProvider.TOASTR_CONFIG
      );
      return;
    }
    if (this.imageToBeUploaded && !this.isFileSizeValid()) {
      this.toastr.error(
        '',
        AppConstantsProvider.ERROR_MSG_CONSTANS.UPLOAD_IMAGE_SIZE_MEMORY,
        AppConstantsProvider.TOASTR_CONFIG
      );
      return;
    }

    const expirtyDate =
      this.helperService.formatJsonToDateString(
        this.editFeatureObj.expiryDate
      ) + ' 23:59:59';
    let reqEditObj = {
      id: buildingData.id,
      title: this.editFeatureObj.title,
      description: this.editFeatureObj.description,
      expiryDate: expirtyDate,
      timeZone: this.helperService.timeZone,
      featuredImg: this.base64OfImageToBeUploaded,
    };
    this.loader.showLoader();
    this.buildingInfoService.updateAppFeatures(reqEditObj).subscribe(
      (response: AppFeatureResponse) => {
        if (response.success) {
          this.loader.hideLoader();
          this.toastr.success(
            '',
            response.message,
            AppConstantsProvider.TOASTR_CONFIG
          );
          this.fetchAllFeaturesComDetails();
        } else {
          this.loader.hideLoader();
          this.toastr.error(
            '',
            AppConstantsProvider.ERROR_MSG_CONSTANS.ERROR_UPDATING_BUILDING,
            AppConstantsProvider.TOASTR_CONFIG
          );
        }
      },
      (error: HttpErrorResponse) => {
        this.loader.hideLoader();
        this.helperService.handleHttpErrorResponse(
          error,
          AppConstantsProvider.ERROR_MSG_CONSTANS.UNABLE_TO_UPDATE_BUILDING
        );
      }
    );
  }

  onDeleteFeatureClicked(selectedFeatureDetails, $event) {
    $event.stopPropagation();
    this.confirmationDialogService
      .confirm(
        'Delete Feature',
        'Are you sure you want to delete this feature?'
      )
      .then((confirmed) => {
        if (confirmed) {
          this.deleteAppFeature(selectedFeatureDetails);
        }
      })
      .catch(() => {});
  }

  deleteAppFeature(selectedFeatureDetails) {
    this.loader.showLoader();
    this.buildingInfoService
      .deleteAppFeatures(selectedFeatureDetails)
      .subscribe(
        (response: AppFeatureResponse) => {
          if (response.success) {
            this.loader.hideLoader();
            this.fetchAllFeaturesComDetails();
            this.toastr.success(
              '',
              response.message,
              AppConstantsProvider.TOASTR_CONFIG
            );
          } else {
            this.loader.hideLoader();
            this.toastr.error(
              '',
              AppConstantsProvider.ERROR_MSG_CONSTANS.ERROR_DELETING_BUILDING,
              AppConstantsProvider.TOASTR_CONFIG
            );
          }
        },
        (error: HttpErrorResponse) => {
          this.loader.hideLoader();
          this.helperService.handleHttpErrorResponse(
            error,
            AppConstantsProvider.ERROR_MSG_CONSTANS.UNABLE_TO_DELETE_BUILDING
          );
        }
      );
  }
  /**
   * Event listener to be fired while image is uploaded
   * @param $event
   */
  imageUploadListener($event): void {
    this.readUploadedImage($event.target);
  }

  // 3MB = 3,145,728  Bytes
  isFileSizeValid(): boolean {
    return this.imageToBeUploaded.size <= 3145728;
  }

  /**
   * To read the Image file and convert into base64 string.
   * @param inputImage
   */
  readUploadedImage(inputImage: any): void {
    this.imageToBeUploaded = inputImage.files[0];
    var imageReader: FileReader = new FileReader();
    if (this.isFileSizeValid()) {
      imageReader.onloadend = (e) => {
        this.base64OfImageToBeUploaded = imageReader.result;
      };
      imageReader.readAsDataURL(this.imageToBeUploaded);
    } else {
      this.toastr.error(
        '',
        AppConstantsProvider.ERROR_MSG_CONSTANS.UPLOAD_IMAGE_SIZE_MEMORY,
        AppConstantsProvider.TOASTR_CONFIG
      );
    }
  }

  clearUploadedImage()
  {
    this.base64OfImageToBeUploaded = null;
    this.imageToBeUploaded = null;
  }



   fetchBanners(): void {
    this.buildingInfoService.getAllBanners().subscribe((res: any[]) => {
      this.bannerList = res;
    });
  }

  openBannerModal(banner?: Banner): void {
    this.bannerForm.reset();
    this.isEditingBanner = !!banner;
    this.editingBannerId = (banner && banner.id) ? banner.id : null;

    if (banner) {
      this.bannerForm.patchValue({
        title: banner.title,
        description: banner.description
      });
    }

    this.modalService.open(this.bannerModalTemplate, { centered: true, size: 'lg' });
  }

  saveBanner(modalRef: any): void {
    if (this.bannerForm.invalid) return;
    this.isBannerSaving = true;
    const payload = {
      ...this.bannerForm.value
    };

    const request = this.isEditingBanner
      ? this.buildingInfoService.updateBanner({ ...payload, id: this.editingBannerId })
      : this.buildingInfoService.addBanner(payload);

    request.subscribe({
      next: () => {
        modalRef.close();
        this.fetchBanners();
      },
      error: (err) => {
        console.error('Banner save error:', err);
      },
      complete: () => {
        this.isBannerSaving = false;
      }
    });
  }

  deleteBanner(banner: any, event?: Event) {
  if (event) {
    event.stopPropagation();
  }

  this.confirmationDialogService
    .confirm('Delete Banner', 'Are you sure you want to delete this banner?')
    .then((confirmed) => {
      if (confirmed) {
        this.isBannerDeleting = true;
        this.buildingInfoService.deleteBanner({ id: banner.id }).subscribe({
      next: () => {
        this.bannerList = [];
        this.isBannerDeleting = false;
        this.fetchBanners();
      },
      error: (err) => {
        this.isBannerDeleting = false;
        console.error('Failed to delete banner:', err);
      }
    });
      }
    })
    .catch(() => {});
}
}



<section class="page-head__block-black">
  <div class="row m-0">
    <div class="col-md-12 page-head__block-title">
      <h1 class="h2 m-0">Search Feature</h1>

      <div class="d-flex flex-row search-loc-fields mb-3">
        <div class="form-group form-inline col-3 pl-0 search-building m-0">
          <input class="form-control ml-0 icon-search icon-props w-100 default-search-box-h" type="text"
            [(ngModel)]="searchTerm" (ngModelChange)="filterFeatureDetails()" />
        </div>
        <!-- <div class="page-limit-ctrls d-flex flex-row">
          <div class="pagelimit-ddown">
            <label class="mr-2 ml-2">Show</label>
            <select [(ngModel)]="pageLimit" class="form-control page-limit" (change)="getPaginatorData()">
              <option value="15" selected>15</option>
              <option value="30">30</option>
              <option value="50">50</option>
              <option value="100">100</option>
            </select>
            <label class="ml-2" >Entries</label>
          </div>
        </div> -->
      </div>
    </div>
  </div>
</section>

<div class="mt-4">
 <div class="form-accordion__container fluid-padding">
   <div class="form-accordion form-accordion-no-plus-minus-icon">
  <div class="form-header row d-flex align-items-center border-top border-bottom py-2">
    <div class="col-md-6 font-weight-bold">Banner Name</div>
    <div class="col-md-4 font-weight-bold">Description</div>
    <div class="col-md-2 text-right">
      <button class="btn btn-sm btn-primary btn-round" (click)="openBannerModal()" [disabled]="bannerList.length > 0">Add Banner</button>
    </div>
  </div>  

  <ng-container *ngIf="bannerList.length > 0; else noBannerBlock">
  <div class="row m-0 border-top py-2 align-items-center">
    <div class="col-md-6">{{ bannerList[0].title }}</div>
    <div class="col-md-4">{{ bannerList[0].description }}</div>
    <div class="col-md-2 text-right">
      <button
        title="Edit banner"
        class="btn btn-sm icon-edit p-tb-0"
        (click)="openBannerModal(bannerList[0])">
        Edit
      </button>
      <button
        title="Delete banner"
        class="btn btn-sm icon-trash p-tb-0"
        (click)="deleteBanner(bannerList[0], $event)">
        <span *ngIf="isBannerDeleting" class="spinner-border spinner-border-sm mr-2" role="status" aria-hidden="true"></span>
        Delete
      </button>
    </div>
  </div>
</ng-container>

  <ng-template #noBannerBlock>
    <div class="row py-3 border-top">
      <div class="col text-muted text-center small">
        No banners found. Click <strong>Add Banner</strong> to create one.
      </div>
    </div>
  </ng-template>
</div>
</div>
</div>

<div class="form-accordion__container fluid-padding">
<hr class="my-4" style="border-top: 1px solid #ccc"/>
</div>

<div class="form-accordion__container fluid-padding">
  <div class="form-accordion form-accordion-no-plus-minus-icon">
    <div class=" form-header row d-flex align-items-center">
      <ng-container *ngIf="!addFeatureClicked else addFeatureTitle">
        <div class="col-md-6">Feature Name</div>
        <div class="col-md-2">Expiry Date</div>
      </ng-container>
      <ng-template #addFeatureTitle>
        <div class="col-md-8">Add a Feature</div>
      </ng-template>
      <div class="col text-right d-flex justify-content-end">
        <button title="Preview" class="custom-btn btn btn-dark btn-sm btn-round btn-primary text-right"
          *ngIf="featureAddActionType === FeatureAddActionType.CANCEL_ADD  && loggedInUserDetailsService.getLoggedInUserRoleName() === userRoleName.SUPER_ADMIN"
          (click)="onClickFeatureComm()">
          Preview</button>
      </div>
      <div class="col text-right d-flex justify-content-end">
        <button title="Add a feature" class="custom-btn btn btn-dark btn-sm btn-round btn-primary text-right"
          *ngIf="featureAddActionType === FeatureAddActionType.CANCEL_ADD  && loggedInUserDetailsService.getLoggedInUserRoleName() === userRoleName.SUPER_ADMIN"
          (click)="showAddFeature($event)">
          Add Feature</button>
      </div>
    </div>

    <ng-container class="addBuildingContainer" *ngIf="featureAddActionType === FeatureAddActionType.ADD">
      <div class="row">
        <div class="col-md-6  p-2 my-3">
          <div class="row">
            <div class="col-md-6">
              <span>*Title</span>
              <input class="form-control" type="text" placeholder="Enter Feature Title" [(ngModel)]="addFeatureObj.title">
            </div>
            <div class="col-md-6">
              <span>*Expiry Date</span>
              <div class="input-group icon-calendar input-group-hasicon">
                <input class="form-control" placeholder="yyyy-mm-dd" name="dp" [minDate]="minDate" (click)="d.toggle()"
                  [(ngModel)]="addFeatureObj.expiryDate" ngbDatepicker #d="ngbDatepicker">
              </div>
            </div>
            <div class="col md-12 mt-4">
              <span>Image</span>
              <input class="form-control" type="file" accept="image/png, image/jpeg"
                (change)="imageUploadListener($event)" />
            </div>
            <div class="col-md-12 mt-4">
              <span>*Description</span>
              <quill-editor class="ql-container" [(ngModel)]="addFeatureObj.description"
                          [modules]="editorConfig">
                      </quill-editor>
            </div>
          </div>
        </div>
        <div class="col-md-6 p-1 my-3"> <!-- preview-image -->
          <img class="w-100 preview-image" [src]="base64OfImageToBeUploaded || featureDetails?.featuredImg" alt="featuredImg" *ngIf="base64OfImageToBeUploaded || featureDetails?.featuredImg">

        </div>
        <div class="col-12 custom-btn-data py-2">
          <button class="btn btn-outline-primary rounded-pill mr-4" title="Cancel adding a feature"
            (click)="cancelAddFeature()">
            Cancel
          </button>
          <button class="btn btn-primary rounded-pill" title="Add feature" (click)="addAppFeature()">
            Add
          </button>
        </div>
      </div>
    </ng-container>

    <ngb-accordion [closeOthers]=" true" id="preventchange-2" (panelChange)="panelStatusChanged($event)">
      <ng-container *ngIf="filteredFeatureData && filteredFeatureData.length>0">
        <ng-container *ngFor="let data of filteredFeatureData; index as i">
          <ngb-panel id={{i}}>
            <ng-template ngbPanelTitle>
              <div class="row m-0" *ngIf="!data.editBuilding">
                <div class="col-md-6">
                  {{data.title}}
                </div>
                <div class="col-md-2">
                  {{data.expiryDate | date: 'MMM-dd-yyyy'}}
                </div>
                <div class="col-md-2"
                  *ngIf="loggedInUserDetailsService.getLoggedInUserRoleName() === userRoleName.SUPER_ADMIN">
                  <button title="Edit feature" class="btn  btn-sm icon-edit p-tb-0"
                    (click)="onEditFeatureIconClick(data,$event)">
                    Edit</button>
                </div>
                <div class="col-md-2"
                  *ngIf="loggedInUserDetailsService.getLoggedInUserRoleName() === userRoleName.SUPER_ADMIN">
                  <button title="Delete feature" class="btn  btn-sm icon-trash p-tb-0"
                    (click)="onDeleteFeatureClicked(data,$event)">Delete</button>
                </div>
              </div>
              <div *ngIf="data.editBuilding">
                <div class="row">
                  <div class="col-md-6">
                    <div class="row">
                      <div class="col-md-6">
                        <span>*Title</span>
                        <input class="form-control" type="text" placeholder="Enter Location Name" [(ngModel)]="editFeatureObj.title">
                      </div>
                      <div class="col-md-6">
                        <span>*Expiry Date</span>
                        <div class="input-group icon-calendar input-group-hasicon">
                          <input class="form-control" placeholder="yyyy-mm-dd" name="dp" [minDate]="minDate" (click)="d.toggle()"
                            [(ngModel)]="editFeatureObj.expiryDate" ngbDatepicker #d="ngbDatepicker">
                        </div>
                      </div>
                      <div class="col-md-12 mt-4">
                        <span>Image</span><br />
                        <span *ngIf="editFeatureObj.featuredImg; else addImage">
                          <input type="file" accept="image/png, image/jpeg" (change)="imageUploadListener($event)" id="img"
                            style="display:none;" />
                          <label class="form-control" for="img">Click here to update the Image</label>
                        </span>
                        <ng-template #addImage>
                          <input class="form-control" type="file" accept="image/png, image/jpeg" (change)="imageUploadListener($event)"
                            title="Upload Image" />
                        </ng-template>
                      </div>
                      <div class="col-md-12 mt-4">
                        <span>*Description</span>
                        <quill-editor class="ql-container" [(ngModel)]="editFeatureObj.description"
                          [modules]="editorConfig">
                      </quill-editor>
                      </div>
                    </div>
                  </div>
                  <div class="col-md-6">
                     <img [src]="base64OfImageToBeUploaded || data?.featuredImg" class="w-100 preview-image" alt="featuredImg" *ngIf="base64OfImageToBeUploaded || data?.featuredImg">
                  </div>
                  <div class="col-12 mb-3 custom-btn-data py-1">
                    <button title="Discard Changes" class="btn btn-sm btn-round btn-outline-primary mr-4"
                      (click)="onUpdateFeatureCancel(data,$event)">
                      Cancel</button>
                    <button title="Update feature details" class="btn btn-dark btn-sm btn-round btn-primary"
                      (click)="onUpdateFeatureClicked(data)">
                      Update</button>
                  </div>
                </div>
              </div>
            </ng-template>
          </ngb-panel>
        </ng-container>
      </ng-container>
    </ngb-accordion>
  </div>
</div>

<div *ngIf="filteredFeatureData&& filteredFeatureData.length==0 && showNoDataMsg" class="not-found">
  <p>No Data Found</p>
</div>

<ng-template #bannerModal let-modal>
  <div class="modal-header">
    <h5 class="modal-title">{{ isEditingBanner ? 'Edit Banner' : 'Add Banner' }}</h5>
    <button type="button" class="close" aria-label="Close" (click)="modal.dismiss()">
      <span aria-hidden="true">&times;</span>
    </button>
  </div>

  <form [formGroup]="bannerForm" (ngSubmit)="saveBanner(modal)">
    <div class="modal-body">
      <div class="form-group">
        <label>Banner Title *</label>
        <input class="form-control" formControlName="title" />
      </div>

      <div class="form-group">
        <label>Description *</label>
        <textarea class="form-control" rows="4" formControlName="description"></textarea>
      </div>
    </div>

    <div class="modal-footer">
      <button type="submit" class="btn btn-primary" [disabled]="bannerForm.invalid || isBannerSaving">
        <span *ngIf="isBannerSaving" class="spinner-border spinner-border-sm mr-2" role="status" aria-hidden="true"></span>
        {{ isEditingBanner ? 'Update' : 'Save' }}
      </button>
      <button type="button" class="btn btn-outline-secondary" (click)="modal.dismiss()">Cancel</button>
    </div>
  </form>
</ng-template>
