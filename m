From: Joel Granados <joel.granados@kernel.org>
Subject: [PATCH RFC 0/8] nvme: Add Controller Data Queue to the nvme driver
Date: Mon, 14 Jul 2025 11:15:31 +0200
Message-Id: <20250714-jag-cdq-v1-0-01e027d256d5@kernel.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALPKdGgC/2WMwQ7CIBAFf6XZsxgg7ZZ6MjHxA7yaHhpYKdpQB
 UM0Df8u4epx3pvMBpGCowiHZoNAyUW3+gJi14CeJ2+JOVMYJJcdR9my+2SZNi+GgyDTEyotNBT
 7GejmPrV0hcv5BGMZZxffa/jWehL1+gslwThDo1Tbox4EdscHBU/Lfg0WxpzzD1mBltGkAAAA
X-Change-ID: 20250624-jag-cdq-691ed7e68c1c
To: Keith Busch <kbusch@kernel.org>, Jens Axboe <axboe@kernel.dk>, 
 Christoph Hellwig <hch@lst.de>, Sagi Grimberg <sagi@grimberg.me>
Cc: Klaus Jensen <k.jensen@samsung.com>, linux-nvme@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=4389;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=zS6VbmY2/RybXP3UyojwlEvFgfhlfkfBDejeGq0mTIA=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGh0ytGtPG+l1LweQR7iTuNvP6BUlhF5HuG67
 oagAOMaESxiOokBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJodMrRAAoJELqXzVK3
 lkFP7tEL/A4VNMYVwcrjZqZXpKzV4h+MR1GMtPQSHmdn35iSQWudMJt6TGW0+6KcFv8hzYcgsam
 NjlkJYiCSPVkopzY5xQFFLo0wkNLCAqxq4xTRtlH4z9+zO7pyOZkVVOBmFG2Qhbq7OuvTQWWlPP
 vrchIRtSV45qnJzT1+TEPlKQNFT5T/woc159rD4bQ0Un746Jmm386d7fRcwGRrSdXDrkdUFkQU1
 ZvdG3vfvaVscnUkuTnbvaf6SHTUgVjH8DIg3St53nU//P1e9e79t2FyWeR9oW8KovdQT105TwgX
 LzPd7WZJEarIVyjh6D8jrJTSBc73oKCDHnybYXeE9NGA/6lMszDjzjMGDIyUpEk6A3bp2crE2/d
 JSa4KX35awaX+3xunSDU/LFAyK8K99ziuzhxaHnWshKAPqMzBXm0AVYXbK9BRd9sghDtLJY37QG
 KFAHkZEC6aMYYSoJIGTYSU4nUlJ6P5XxFA/D9EsA8KV8d0g7K5/tIg0PFlTYBMsIc0kH1GEyMr7
 AM=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series introduces support for Controller Data Queues (CDQs) in the
NVMe driver. CDQs allow an NVME controller to post information to the
host through a single completion queue. This series adds data structures,
helpers, and the user interface required to create, read, and delete CDQs.

Motivation
==========
The main motivation is to enable Controller Data Queues as described in
the 2.2 revision of the NVME base specification. This series places the
kernel as an intermediary between the NVME controller producing CDQ
entries and the user space process consuming them. It is general enough
to encompass different use cases that require controller initiated
communication delivered outside the regular I/O traffic streams (like
LBA tracking for example).

What is done
============
* Added nvme_admin_cdq opcode and NVME_FEAT_CDQ feature flag
* Defined a new struct nvme_cdq command for create/delete operations
* Added a cdq_nvme_queue struct that holds the CDQ state
* Added an xarray for each nvme_ctrl that holds a reference to all
  controller CDQs.
* Added a new ioctl (NVME_IOCTL_ADMIN_CDQ) and argument struct
  (nvme_cdq_cmd) for CDQ creation
* Added helpers for consuming CDQs: nvme_cdq_{next,send_feature,traverse}
* Added helpers for CDQ admin: nvme_cdq_{free,alloc,create,delete}

In summary, this series implements creation, consumption, and cleanup of
Controller Data Queues, providing a file-descriptor based interface for
user space to read CDQ entries.

CDQ life cycle
==============
To create a CDQ, user space defines the number of entries, entry size,
location of the phase tag (8.1.6.2 NVME base spec), MOS field (5.1.4
NVME base spec) and if necessary, CQS field (5.1.4.1.1 NVME base spec).
All these are passed through the NVME_IOCTL_ADMIN_CDQ ioctl which
allocates and connects the controller to CDQ memory and returns the CDQ
ID (defined by the controller) and a CDQ file descriptor (CDQ FD).

The CDQ FD is used to consume entries through read system call. For
every "read", all available (new) entries are copied from the
internal Kernel CDQ buffer to the user space buffer.

The CDQ ID, on the other hand, is meant for interactions that are
outside CDQ creation and consumption. In these cases the caller is
expected to send NVME commands down through one of the already available
mechanisms (like the NVME_IOCTL_ADMIN_CMD ioctl).

CDQ data structures and memory are cleaned up when the release file
operation is called on the FD, which usually means the close system call
or the user process gets killed.

Testing
=======
The User Data Migration Queue (5.1.4.1.1 NVME base spec) implemented in
the QEMU NVME device [1] is used for testing purposes. CDQ creation,
consumption and deletion is shown by calling a CDQ example in libvfn [2]
(a low level NVME/PCIe library) from within QEMU. For brevity, I have
*not* included any of the testing commands; but I can provide them if
needed.

Questions
=========

Here are some questions that where on my mind.

1. I have used an ioctl for the CDQ creation. Any better alternatives?
2. The deletion is handled by closing the file descriptor. Should this
   be handled by the ioctl?

Any feedback, questions or comments is greatly appreciated

Best

[1] https://github.com/SamsungDS/qemu/tree/nvme.tp4159
[2] https://github.com/Joelgranados/libvfn/blob/jag/cdq/examples/cdq.c

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
Joel Granados (8):
      nvme: Add CDQ command definitions for contiguous PRPs
      nvme: Add cdq data structure to nvme_ctrl
      nvme: Add file descriptor to read CDQs
      nvme: Add function to create a CDQ
      nvme: Add function to delete CDQ
      nvme: Add a release ops to cdq file ops
      nvme: Add Controller Data Queue (CDQ) ioctl command
      nvme: Connect CDQ ioctl to nvme driver

 drivers/nvme/host/core.c        | 253 ++++++++++++++++++++++++++++++++++++++++
 drivers/nvme/host/ioctl.c       |  47 +++++++-
 drivers/nvme/host/nvme.h        |  20 ++++
 include/linux/nvme.h            |  30 +++++
 include/uapi/linux/nvme_ioctl.h |  12 ++
 5 files changed, 361 insertions(+), 1 deletion(-)
---
base-commit: 0ff41df1cb268fc69e703a08a57ee14ae967d0ca
change-id: 20250624-jag-cdq-691ed7e68c1c

Best regards,
-- 
Joel Granados <joel.granados@kernel.org>

