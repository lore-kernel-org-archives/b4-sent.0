From: Joel Granados <j.granados@samsung.com>
Subject: [PATCH 0/6] iommu: Enable user space IOPFs in non-nested and
 non-svm cases
Date: Wed, 04 Sep 2024 15:17:11 +0200
Message-Id: <20240904-jag-iopfv8-v1-0-e3549920adf3@samsung.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANdd2GYC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDSwMT3azEdN3M/IK0MgtdQ1Nz87QUIwMTI6MUJaCGgqLUtMwKsGHRsbW
 1AHfUe3lcAAAA
To: David Woodhouse <dwmw2@infradead.org>, 
 Lu Baolu <baolu.lu@linux.intel.com>, Joerg Roedel <joro@8bytes.org>, 
 Will Deacon <will@kernel.org>, Robin Murphy <robin.murphy@arm.com>, 
 Jason Gunthorpe <jgg@ziepe.ca>, Kevin Tian <kevin.tian@intel.com>, 
 Klaus Jensen <its@irrelevant.dk>
Cc: linux-kernel@vger.kernel.org, iommu@lists.linux.dev, 
 Joel Granados <j.granados@samsung.com>, Klaus Jensen <k.jensen@samsung.com>
X-Mailer: b4 0.15-dev-00a43
X-Developer-Signature: v=1; a=openpgp-sha256; l=5618;
 i=j.granados@samsung.com; h=from:subject:message-id;
 bh=eo+YPOw/9Fbe9qLjCDpKIzXuR4NNxNWayvZdDd9d1cA=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGbYXg/iMiFK3B0UgMirC16jX7+eAAQSzEoay
 UXGgkZW5yPdG4kBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJm2F4PAAoJELqXzVK3
 lkFPR0UMAIIBKo13YqnyTV1NVThmoDvNR+OkwIxzTtH8wPufGhMFrmQ+cgYEufP6hAUgA6SCwqM
 tJxqQyoBcaNsVWUQnrt3//J1c0CZb3hpZ69yjRSOud4j225aDojf687lAYkQA1A10zlHxUckmDU
 qAKVihkuTJQGjFtY1xu+h9XH7lc0uGJz6G3LQvJNXtZFG9MAdmsp/gwEEx/orPJl6xG4Xkn3d1+
 OlBEdNSPWEodOc74cVoDJ+fS8b1Tj6EoovSxm5+963gc5c/BxLBg/DUSa+vFJCfTvdzGa4L3szP
 9csKedSk3GsTN844lJDqKZnkJA0/71ZQg44yvBWn/rZVFmDRirMTSIWSx5v7iACSmRJvm4T2YhJ
 pFZrgRUlRIMjvlScMAWPsVH6r2g3yCR5OUqRCsZUebTwy38n4pE7HEFYbfSWXlYuPEIa0OiQ1di
 JK90wNyCb1SoRlpYHgvm65AZYT/QrL4IEhn6uSwK2Do71UkblSFmCmPjqixN2wf/jRt5+mUZll5
 1A=
X-Developer-Key: i=j.granados@samsung.com; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for j.granados@samsung.com/default with auth_id=70
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series makes use of iommufd_hwpt_replace_device to execute
non-nested and non-svm user space IOPFs. Our main motivation is to
enable user-space driver driven device verification without PASID,
nesting nor SVM.

What?
  * Enable IO page fault handling in user space for a non-nested,
    non-svm and non-virtualised use case.
  * Move IOMMU_IOPF configuration from INTEL_IOMMU_SVM into INTEL_IOMMU.
  * Move all page request queue related logic to a new (prq.c) file.
  * Remove PASID checks from PRQ event handling as well as PRQ
    initialization.
  * Allow execution of IOMMU_HWPT_ALLOC with a valid fault id
    (IOMMU_HWPT_FAULT_ID_VALID)
  * Insert a zero handle into the PASID array in dev->iommu_group when
    replacing the old HWPT with an IOPF enabled HWPT.

Why?
  The PCI ATS Extended Capability allows peripheral devices to
  participate in the caching of translations when operating under an
  IOMMU. Further, the ATS Page Request Interface (PRI) Extension allows
  devices to handle missing mappings. Currently, PRI is mainly used in
  the context of Shared Virtual Addressing, requiring support for the
  Process Address Space Identifier (PASID) capability, but other use
  cases such as enabling user-space driver driven device verification
  and reducing memory pinning exists. This patchest sets out to enable
  these use cases.

Testing?
  The non-nested/non-svm IOPF interface is exercised by first
  initializing an IOPF enabled IOAS and then reading the fault file
  descriptor. Pseudocode on the iopf initializing and handling is in [3]
  and [4] (using libvfn).

  Supplementary repositories supporting this patchset:
    1. A user space library libvfn [1] which is used for testing and
       verification (see examples/iopf.c), and
    2. Basic emulation of PCIe ATS/PRI and Intel VT-d PRQ in QEMU [2].

V1:
  * This is the first version of the series after initial feedback from
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
Joel Granados (4):
      iommu/vt-d: Separate page request queue from SVM
      iommu: kconfig: Move IOMMU_IOPF into INTEL_IOMMU
      iommufd: Enable PRI when doing the iommufd_hwpt_alloc
      iommu: init pasid array while doing domain_replace and iopf is active

Klaus Jensen (2):
      iommu/vt-d: Remove the pasid present check in prq_event_thread
      iommu/vt-d: drop pasid requirement for prq initialization

 drivers/iommu/intel/Kconfig          |   2 +-
 drivers/iommu/intel/Makefile         |   2 +-
 drivers/iommu/intel/iommu.c          |  29 +--
 drivers/iommu/intel/iommu.h          |  14 +-
 drivers/iommu/intel/prq.c            | 404 +++++++++++++++++++++++++++++++++++
 drivers/iommu/intel/svm.c            | 397 ----------------------------------
 drivers/iommu/iommu-priv.h           |   3 +
 drivers/iommu/iommu.c                |  30 +++
 drivers/iommu/iommufd/fault.c        |  22 ++
 drivers/iommu/iommufd/hw_pagetable.c |   3 +-
 10 files changed, 480 insertions(+), 426 deletions(-)
---
base-commit: 431c1646e1f86b949fa3685efc50b660a364c2b6
change-id: 20240904-jag-iopfv8-1577fd20422d

Best regards,
-- 
Joel Granados <j.granados@samsung.com>

