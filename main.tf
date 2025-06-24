saveBanner(modalRef: any): void {
  if (this.bannerForm.invalid) return;

  this.isBannerSaving = true;
  this.loader.showLoader();

  const payload = {
    ...this.bannerForm.value
  };

  const request = this.isEditingBanner
    ? this.buildingInfoService.updateBanner({ ...payload, id: this.editingBannerId })
    : this.buildingInfoService.addBanner(payload);

  request.subscribe({
    next: (response: any) => {
      this.toastr.success(
        '',
        this.isEditingBanner ? 'Banner updated successfully!' : 'Banner added successfully!',
        AppConstantsProvider.TOASTR_CONFIG
      );
      modalRef.close();
      this.fetchBanners();
    },
    error: (err) => {
      console.error('Banner save error:', err);
      this.toastr.error(
        '',
        'Failed to save banner. Please try again.',
        AppConstantsProvider.TOASTR_CONFIG
      );
    },
    complete: () => {
      this.isBannerSaving = false;
      this.loader.hideLoader();
    }
  });
}
