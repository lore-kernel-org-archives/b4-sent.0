From: Joel Granados <joel.granados@kernel.org>
Subject: [PATCH v3 0/5] iommu: Enable user space IOPFs in non-PASID and
 non-svm cases
Date: Wed, 09 Oct 2024 09:28:08 +0200
Message-Id: <20241009-jag-iopfv8-v3-0-bd4271df5b2b@kernel.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIgwBmcC/23MQQ7CIBCF4as0rMUMA02tK+9hXCAMLSYtDSjRN
 L27tCubuHwv+f6ZJYqeEjtXM4uUffJhLEMeKmZ6PXbEvS2bIaCCFhR/6I77MLl84qJuGmcRFKJ
 lBUyRnH9vseut7N6nZ4ifrZ3F+v7NZMGBk6xV2yJo6+Ql6SG9xu5owsDWUMYfLOQOY8GWNAiDU
 sm72eNlWb4bE9eL4wAAAA==
To: David Woodhouse <dwmw2@infradead.org>, 
 Lu Baolu <baolu.lu@linux.intel.com>, Joerg Roedel <joro@8bytes.org>, 
 Will Deacon <will@kernel.org>, Robin Murphy <robin.murphy@arm.com>, 
 Jason Gunthorpe <jgg@ziepe.ca>, Kevin Tian <kevin.tian@intel.com>, 
 Klaus Jensen <its@irrelevant.dk>
Cc: linux-kernel@vger.kernel.org, iommu@lists.linux.dev, 
 Joel Granados <joel.granados@kernel.org>, 
 Joel Granados <joel.granados@kernel.org>, 
 Klaus Jensen <k.jensen@samsung.com>
X-Mailer: b4 0.15-dev-00a43
X-Developer-Signature: v=1; a=openpgp-sha256; l=6148;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=e2RQ0yEJePuriXcYPICTyw+6zC1cWX7pdNTOj+y2Y58=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGcGMIuRohnjV0fdnj9+LEdUOwbAGkaItpdiT
 AbEtkmqvBqdJYkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJnBjCLAAoJELqXzVK3
 lkFPgQQMAJZvYyiW0SPtZekEOm3EjYD1QjETNVTxeiK0dszZD1Xm0AA0gbhwVTJi8rWgNibxNO0
 62WeSnkv0onkZlpUck3BSKyzZSzK0h5/SOe8btY4ExbbCm5qm4d4QNz0mjCWIBZbXwdAJHxENz4
 95yp7ypNx+liu0n2SSFfwf7rWT8/5CzVmq5id1mA41YrwREPCgI0IGarQvZjOkPGMJ7abNLNQ+r
 MZec8eu5iQUiHlRfiy2eAyQ7X2yy/ncJownZ3qkqItywlVVcSg1IdkrNy0V2RSSUQY1t4YX0z8H
 x8Zm708oJRmyF4OFsxjVsCSDYZ1brHTqKIwEVh3HRoIDOMrPhDyC10UpuPf9ciBl3H3loWxaBoe
 8rSlWpAxWy34k+EJO9j0UBgaiBoPOgywePQ4gKt5MFz4CYqOqHeO6TwUfn6ot+RUCyx5n9Z7KHb
 kDMbxxd03qjPlnsTNx9JxMWLNFo2aovwL5yXztAtrhywjI78mWkgByK8PF3Ln12Am7rK23krDL3
 lE=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series makes use of iommufd_hwpt_replace_device to execute
non-pasid/non-svm user space IOPFs. Our main motivation is to expand or
facilitate user-space driver driven device verification by enabling IOPF
without SVM/PASID.

What?
  * Enable IO page fault handling in user space for a non-pasid, non-svm
    and non-virtualised use case.
  * Move IOMMU_IOPF configuration from INTEL_IOMMU_SVM into INTEL_IOMMU.
  * Move all page request queue related logic to a new (prq.c) file.
  * Remove PASID checks from PRQ event handling as well as PRQ
    initialization.
  * Allow execution of IOMMU_HWPT_ALLOC with a valid fault id
    (IOMMU_HWPT_FAULT_ID_VALID)

Why?
  The PCI ATS Extended Capability allows peripheral devices to
  participate in the caching of translations when operating under an
  IOMMU. Further, the ATS Page Request Interface (PRI) Extension allows
  devices to handle missing mappings. Currently, PRI is mainly used in
  the context of Shared Virtual Addressing, requiring support for the
  Process Address Space Identifier (PASID) capability which is not
  strictly necessary. Relaxing this requirement adds to the
  possibilities available for user-space driver driver device
  verification as well as for avoiding pinning.

Testing?
  The non-svm IOPF interface is exercised by first initializing an IOPF
  enabled IOAS and then reading the fault file descriptor. Pseudocode on
  the IOPF initializing and handling is in [3] and [4] (using libvfn).

  Supplementary repositories supporting this patchset:
    1. A user space library libvfn [1] which is used for testing and
       verification (see examples/iopf.c), and
    2. Basic emulation of PCIe ATS/PRI and Intel VT-d PRQ in QEMU [2].

Changes in v3:
- Adjust wording in cover letter
- Include "_iommu_" in the prq Intel function names to be more in line
  with functions in iommu.h file
- Rebase on top of 6.12-rc2
- Update my ID in e-mail, git author and my Signed-off-by.
- Link to v2: https://lore.kernel.org/r/20240913-jag-iopfv8-v2-0-dea01c2343bc@samsung.com

Changes in v2:
  - Remove "nesting" from wording. This wording is left over from initial
    versions that are now irrelevant.
  - Dropped "iommu: init pasid array while doing domain_replace and iopf
    is active" as the initialization of the pasid_array x-array happens
    automatically when an iopf capable domain is replaced on a device.
  - Corrected commit message in "iommu/vt-d: Separate page request queue
    from SVM"
  - Link to v1: https://lore.kernel.org/r/20240904-jag-iopfv8-v1-0-e3549920adf3@samsung.com

V1:
  - This is the first version of the series after initial feedback from
    the RFC [5].

Comments and feedback are greatly appreciated
Best

Joel

[1] https://github.com/SamsungDS/libvfn/tree/iommufd-fault-queue
[2] https://gitlab.com/birkelund/qemu/-/tree/pcie-ats-pri

[3] Initializing
```
  int iopf_init(struct iommu_ioas *ioas, const char *bdf)
  {
      // open vfio device from bdf
      int devfd = open('/dev/vfio/devices/VFIO_DEV', O_RDWR);

      struct vfio_device_bind_iommufd bind = {
          .argsz = sizeof(bind),
          .flags = 0,
          .iommufd = __iommufd,
      };
      ioctl(devfd, VFIO_DEVICE_BIND_IOMMUFD, &bind);

      struct iommu_ioas *ioas = ioas;
      struct vfio_device_attach_iommufd_pt attach_data = {
          .argsz = sizeof(attach_data),
          .flags = 0,
          .pt_id = ioas->id,
      };
      ioctl(devfd, VFIO_DEVICE_ATTACH_IOMMUFD_PT, &attach_data);

      struct iommu_fault_alloc fault = {
          .size = sizeof(fault),
          .flags = 0,
      };
      ioctl(__iommufd, IOMMU_FAULT_QUEUE_ALLOC, &fault);

      struct iommu_hwpt_alloc fault_cmd = {
          .size = sizeof(fault_cmd),
          .flags = IOMMU_HWPT_FAULT_ID_VALID,
          .dev_id = bind.out_devid,
          .pt_id = ioas->id,
          .data_len = 0,
          .data_uptr = (uint64_t)NULL,
          .fault_id = fault.out_fault_id,
          .__reserved = 0,
          };
      ioctl(__iommufd, IOMMU_HWPT_ALLOC, &fault_cmd);

      // This is a re-attach
      struct vfio_device_attach_iommufd_pt attach = {
          .argsz = sizeof(attach),
          .flags = 0,
          .pt_id = fault_cmd.out_hwpt_id
      };
      ioctl(dev_fd, VFIO_DEVICE_ATTACH_IOMMUFD_PT, &attach);
  }
```

[4] Handling
```
  int handle_iopf(void *vaddr, int len, uint64_t iova) {
    exec_command(CMD)

    int iopf_fd = fault_cmd.fault_id;

    struct iommu_hwpt_pgfault pgfault = {0};
    if(read(iopf_fd, &pgfault, sizeof(pgfault)) == 0);
      return; // no page fault

    ret = iommu_map_vaddr(__iommmufd, vaddr, len, &iova)
    struct iommu_hwpt_page_response pgfault_response = {
      .cookie = pgfault.cookie,
      .code = ret ? IOMMUFD_PAGE_RESP_SUCCESS : IOMMUFD_PAGE_RESP_INVALID,
    };

    write(iopf_fd, &pgfault_response, sizeof(pgfault_response));

    return;
  }
```

[5] https://lore.kernel.org/20240826-iopf-for-all-v1-0-59174e6a7528@samsung.com

Signed-off-by: Joel Granados <j.granados@samsung.com>
---
Joel Granados (3):
      iommu/vt-d: Separate page request queue from SVM
      iommu: kconfig: Move IOMMU_IOPF into INTEL_IOMMU
      iommufd: Enable PRI when doing the iommufd_hwpt_alloc

Klaus Jensen (2):
      iommu/vt-d: Remove the pasid present check in prq_event_thread
      iommu/vt-d: drop pasid requirement for prq initialization

 drivers/iommu/intel/Kconfig          |   2 +-
 drivers/iommu/intel/Makefile         |   2 +-
 drivers/iommu/intel/iommu.c          |  31 ++-
 drivers/iommu/intel/iommu.h          |  14 +-
 drivers/iommu/intel/prq.c            | 406 +++++++++++++++++++++++++++++++++++
 drivers/iommu/intel/svm.c            | 397 ----------------------------------
 drivers/iommu/iommufd/hw_pagetable.c |   3 +-
 7 files changed, 428 insertions(+), 427 deletions(-)
---
base-commit: 8cf0b93919e13d1e8d4466eb4080a4c4d9d66d7b
change-id: 20240904-jag-iopfv8-1577fd20422d

Best regards,
-- 
Joel Granados <joel.granados@kernel.org>

