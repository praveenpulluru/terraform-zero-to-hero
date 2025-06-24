this.bannerForm = this.fb.group({
  title: ['', [Validators.required]],
  description: ['', [Validators.required, Validators.maxLength(440)]]
});


<div class="form-group">
  <label>Description *</label>
  <textarea class="form-control" rows="4" formControlName="description"></textarea>
  <small class="form-text text-muted">
    {{ bannerForm.get('description').value?.length || 0 }}/440 characters
  </small>
</div>


<div class="col-md-4">
  {{ bannerList[0].description }}
</div>
showFullDescription: boolean = false;

toggleDescription() {
  this.showFullDescription = !this.showFullDescription;
}
<div class="col-md-4">
  <ng-container *ngIf="bannerList[0]?.description?.length <= 100 || showFullDescription">
    {{ bannerList[0].description }}
  </ng-container>
  <ng-container *ngIf="bannerList[0]?.description?.length > 100 && !showFullDescription">
    {{ bannerList[0].description | slice:0:100 }}...
    <a href="#" (click)="toggleDescription(); $event.preventDefault()">More</a>
  </ng-container>
  <ng-container *ngIf="showFullDescription && bannerList[0]?.description?.length > 100">
    <a href="#" (click)="toggleDescription(); $event.preventDefault()">Less</a>
  </ng-container>
</div>
