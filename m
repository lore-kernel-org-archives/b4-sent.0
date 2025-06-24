From: Joel Granados <joel.granados@kernel.org>
Subject: [PATCH RFC 0/7] nvme: Add Controller Data Queue to the nvme driver
Date: Tue, 24 Jun 2025 22:05:47 +0200
Message-Id: <20250624-jag-cdq-v1-0-6d88476c9165@kernel.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABsFW2gC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDMyMT3azEdN3klEJdM0vD1BTzVDOLZMNkJaDqgqLUtMwKsEnRSkFuzkq
 xtbUAORdail4AAAA=
X-Change-ID: 20250624-jag-cdq-691ed7e68c1c
To: joshi.k@samsung.com
Cc: Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2747;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=jbWWD1pLgHeYqhKcNvINarVNKzJxigdVrwCGBaNoVcM=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGhbBR06F07xGhgVoBHfghcxUQoU6cyyQHF4B
 urmYUy/FbxRdokBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJoWwUdAAoJELqXzVK3
 lkFP9SkL/jZenv5kFPAPO/TcD30hccGhxXi0/d1HiJN8NcizJY4NLbODQbqxrVmDTL7qCgY37Lj
 NPZgmkTSrfnfGZtxZzAuO6AsTFmEJe7d8xdy+YPpMNisfxHtWBS7cML9YVpYcr1/fOEcAxZHaqM
 N1INMY726NvQSjLjbVDKmHTAmrmjvdhro/MTbv2Wh+ijq6/ElM5LBGp0Y7eEar/81sYUliBaDo7
 JE45bqySsPjel4fzU5LNztku0s4wbMePWoJNIVUuse+h+RAteqEznCIismTVwf2EIApBiPd0yvQ
 DXgYcIILNMimvG+07llCj8kTO5mw0TfbH2/SD5oAebjyqkRgcGaXiHdNBYItVBi1Ua+wE5mw1Ny
 zO9iv2ry1YCZh7Y//E0x1dVeQjV3Xig6GQtGw85GP3zAQENZIGynvVA4JR/nmNV5bcUWs+8wyFF
 gYzHScRqtAcz5ADSaedtv72zeUr89GLMjRYeI1B0gpHk9L+6Vu6dtN1IJJx2LZq4BhnlCuipUI4
 cU=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

@kanchan:
Thx for agreeing to the review. I'll quickly describe what I'm doing and
then list some questions. If you have any doubts or you want to include
anyone else in thread, please get back to me.

Add a cdq xarray into the struct nvme_ctrl that will house all the
Controller Data Queues related to that controller. Use struct
cdq_nvme_queue to hold all relevant state of the CDQ; here you will find
the pointer to the queue head (curr_entry) as well as the entry memory
(entries) and DMA addr (entries_dma_addr). For now all this needs to be
contiguous memory.

A new ioctl has been added to nvme_ioctl.h (NVME_IOCTL_ADMIN_CDQ).
Caller from user space can create and delete CDQs. When creating, the
CDQ id and the CDQ file descriptor will be returned so the user can
interact with the CDQ.

CDQ creation will allocate queue memory, send an NVME command to the
controller to create the CDQ, put the cdq pointer into the xarray and
initialize the file descriptor infrastructure so user space can read the
entries.

The Controller Data Queue is different from regular IO queues in that it
is not a pair. You can think about it as just a completion queue. The
controller fills entries and the host (the kernel) consumes them. There
is not submission queue.

questions:
1. Where do I put the NVME command that terminates the CDQ? ATM it is in
   nvme_free_ctrl with the nvme_free_cdqs call; but I believe that
   sending an NVME command at this point (nvme_free_ctrl) is too late,
   but where else can I put it? Does it have to be in one of the working
   queues? which one?

2. I have a call to dma_alloc_coherent in core.c. which seems a bit
   out of place because there are no others in that file. Is there a
   unspoken rule to not have these there?

Comments and questions are appreciated.

Best

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
Joel Granados (7):
      nvme: Add nvme_cdq to the nmve_command union
      nvme: Add cdq data structure to nvme_ctrl
      nvme: Add file descriptor to read CDQs
      nvme: Add function to create a CDQ
      nvme: Add function to delete CDQ
      nvme: Add Controller Data Queue (CDQ) ioctl command
      nvme: Connect CDQ ioctl to nvme driver

 drivers/nvme/host/core.c        | 269 ++++++++++++++++++++++++++++++++++++++++
 drivers/nvme/host/ioctl.c       |  59 ++++++++-
 drivers/nvme/host/nvme.h        |  20 +++
 include/linux/nvme.h            |  30 +++++
 include/uapi/linux/nvme_ioctl.h |  18 +++
 5 files changed, 395 insertions(+), 1 deletion(-)
---
base-commit: 0ff41df1cb268fc69e703a08a57ee14ae967d0ca
change-id: 20250624-jag-cdq-691ed7e68c1c

Best regards,
-- 
Joel Granados <joel.granados@kernel.org>

