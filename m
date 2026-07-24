From: Joel Granados <joel.granados@kernel.org>
Subject: [PATCH RFC v2 00/14] nvme: Controller Data Queue (CDQ) support
Date: Fri, 24 Jul 2026 13:10:54 +0200
Message-Id: <20260724-jag-cdq-lkml-v2-0-659a7449e849@kernel.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAD5IY2oC/22NwQrCMBBEf6Xs2UibBNd4Kgh+gFfpoSZruramm
 khRSv/d0LO3eTPMzAyJIlOCQzFDpIkTjyGD3BRguzZ4EuwygyzlrtRSi3vrhXUvMfSPIQtzRYv
 G7JWDXHlGuvFnnbvA+XSEJpsdp/cYv+vFVK3R/7WpEqVwiEpp1WKFtu4pBhq2Y/TQLMvyA0kmd
 q2uAAAA
X-Change-ID: 20260424-jag-cdq-lkml-cd9b7c79983d
To: Keith Busch <kbusch@kernel.org>, Jens Axboe <axboe@kernel.dk>, 
 Christoph Hellwig <hch@lst.de>, Sagi Grimberg <sagi@grimberg.me>, 
 Chaitanya Kulkarni <chaitanyak@nvidia.com>, Jason Gunthorpe <jgg@ziepe.ca>
Cc: linux-nvme@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=4574;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=3FEEddZK0tvGfV1cD9Ct9aARj8bT8HD6GQK2Dmyu9e8=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGpjSFgDFZdNUIQa/mgy7TcQ+KyrhfoDBgZ5R
 Ou0BWTgcC7Ym4kBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJqY0hYAAoJELqXzVK3
 lkFP88UMAIrZwgeAblVIdTIUgPCdkMe7KONZmZeXaYOgYk/t+DNeSImAtkIvf5aeI4mHNzc6HSH
 5nTKjMIAqEIGNrPjSGI06LT9b6nH9mLkLEZVqsyo+aM8O4ag83/K0UcXQE8lxdkhIoVmw2r6+p8
 hkp3ET5gqdsHx6hNCjy++etgj6+xZZhuhyl1Zz+rHlFVLF5KxKkZ9T68YNIL+UKlY0U78v8o+ii
 sZEsqCl2v/L7Z9e0RPDqamCuGeoztbQT8Jcphe4+AlmWVscAAmPEBRYJtA5Luv5hpyCcEJaTDsk
 dKrznbAqwWdXJYwkYccyHZioxLtt+XNlG9M/+4GTPw9peCw87rXMbgQbAYY1Op6egySH+fIgdU/
 hLfzCPjlMThYQ6GiTeIYWBV9Doz+A8evWvHC9XJsMNL7xrVCXhUw2gpTu3o4NlwjkX8+/5DVpqg
 2fb3MN0R1rcE6K8I/VWnDCOnK7nt7lERt5Tw4L1I9NuFM+o65cikssez0lxtzh7Yj0RQrgA3Pi5
 3A=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This RFC implements Controller Data Queue (CDQ) support in the NVMe
driver, a variation on my two ([2] & [5]) previously shared approaches.
A CDQ is how an NVMe controller reports modified ranges; user space
consumes that stream to aid in data migration.

Motivation
==========
This is about enabling NVMe namespace migration. The timing feels right
as hardware with CDQ capability exists, NVMe fully specifies the feature
and there is growing interest in Live Migration which by extension
includes CDQ.

What
====
Implement CDQ (the backing memory, the controller-side create/delete,
the queue traversal and the asynchronous-event handling) inside the nvme
driver. User space drives everything through a single ioctl. The CDQ is
read through an FD handed back by the nvme driver, which copies new
entries to a user space buffer. A tail pointer trigger can be armed
automatically when there are no new entries. The one shot AEN event
is routed to an eventfd whenever new entries become available.

NVMe LM SW WG
=============
The NVMe Live Migration SoftWare Working Group (mentioned in [6]) was
one of the main feedback points in my previous RFC. My main goal in this
respect is to keep exploring different approaches in the hope that when
it materializes we can "hit the ground running".

vfio-nvme ([1], [4])
====================
This is what I rebased onto [4] and relates to the handling of
controller state in live migration. I was curious to see how it would
interact (if at all) with my CDQ approach; IMO, for now, they are quite
orthogonal. It is **neither** a rejection nor an endorsement of the vfio
approach. From my point of view there is still no consensus on how this
will make its way into mainline.

Feedback
========
1. The CDQ is introduced into core.c. Would putting it in pci.c make
   more sense?
2. I create a new type of submission-less queue for the CDQ. There is no
   way of using the NVMe queue pairs for a submission-less queue, right?
3. Any feedback that can be shared publicly is greatly appreciated.

As always, please tell me if you want to be removed from these moving
forward or if I have missed someone.

Best

Changes in v2:
- CDQ logic (traversal, memory, AEN, ...) is all in the nvme driver.
- CDQ entries are now copied from the CDQ mem to the user space buffer
- Reduced IOCTL command size
- Rebased on top of [4] (wich is [3] with some fixes from my part)
- Don't wait for the completion of the set feature cmd. We handle it
  separately from sending the command to avoid having to wait for the
  round trip to/from the controller.
- Link to v1: [5]

[1] https://lore.kernel.org/20221206055816.292304-1-lei.rao@intel.com
[2] https://lore.kernel.org/20250714-jag-cdq-v1-0-01e027d256d5@kernel.org
[3] https://lore.kernel.org/20250803024705.10256-1-kch@nvidia.com
[4] https://git.kernel.org/pub/scm/linux/kernel/git/joel.granados/linux.git/log/?h=jag/vfio-nvme
[5] https://lore.kernel.org/r/20260424-jag-cdq-lkml-v1-0-d773343a717c@kernel.org
[6] https://lore.kernel.org/de162155-b03a-4626-a416-3425db9235c7@nvidia.com

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
---
Joel Granados (14):
      nvme: Add NVME_AER_ONE_SHOT callback handler
      nvme: Add NVMe Controller Data Queue command
      nvme: Add track send command
      nvme: Add CDQ to xarray and define delete path
      nvme: Allocate CDQ backing memory from coherent DMA chunks
      nvme: Add file descriptor to read CDQs
      nvme: Add the create CDQ functionality
      nvme: Submit track send command to start/stop the CDQ
      nvme: Coordinate CDQ backing mem and CDQ FD
      nvme: Pin a ctrl ref to every CDQ
      nvme: Implement CDQ traversal on the read path
      nvme: Update the controller with the CDQ set-feature cmd
      nvme: Use eventfd for CDQ Tail pointer triggers
      nvme: Add NVME_IOCTL_CDQ to create/delete migration CDQs

 drivers/nvme/host/Makefile      |   2 +-
 drivers/nvme/host/cdq.c         | 667 ++++++++++++++++++++++++++++++++++++++++
 drivers/nvme/host/cdq.h         | 110 +++++++
 drivers/nvme/host/core.c        |  46 ++-
 drivers/nvme/host/ioctl.c       |  44 ++-
 drivers/nvme/host/nvme.h        |   1 +
 include/linux/nvme.h            |  78 ++++-
 include/uapi/linux/nvme_ioctl.h |  22 ++
 8 files changed, 966 insertions(+), 4 deletions(-)
---
base-commit: 087c08850a40fb37753475f90b0cb706effd752c
change-id: 20260424-jag-cdq-lkml-cd9b7c79983d

Best regards,
-- 
Joel Granados <joel.granados@kernel.org>

