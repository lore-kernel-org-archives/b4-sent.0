From: Joel Granados <joel.granados@kernel.org>
Date: Mon, 14 Jul 2025 11:15:38 +0200
Subject: [PATCH RFC 7/8] nvme: Add Controller Data Queue (CDQ) ioctl
 command
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250714-jag-cdq-v1-7-01e027d256d5@kernel.org>
References: <20250714-jag-cdq-v1-0-01e027d256d5@kernel.org>
In-Reply-To: <20250714-jag-cdq-v1-0-01e027d256d5@kernel.org>
To: Keith Busch <kbusch@kernel.org>, Jens Axboe <axboe@kernel.dk>, 
 Christoph Hellwig <hch@lst.de>, Sagi Grimberg <sagi@grimberg.me>
Cc: Klaus Jensen <k.jensen@samsung.com>, linux-nvme@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1721;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=dv2xzXC+6TJZt9TJ3U/97Y9njM2Cu8lc2Jl+hxwFXTg=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGh0yuzaV4yProMruCg+StvkS6ozjmlyR+D12
 60MLLqag8RnjokBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJodMrsAAoJELqXzVK3
 lkFPhosL/10webJ+d9JVE+imM2vxDxzAqBP41TUHUEaBoxiWc5QMF2R1JzIGW6HrfyPN3JXplP8
 RAiqMmOBG28z+vGVt2c/BUKIlSN+X/ba7vXkGWIWjLqB+lMcr62mJDmf20cTjKa2pgZ1udbqd5G
 WuH1VkC4tDeGyvIy+qmgecW+zQOjUlTfeKz2e2KIhDgErp7m1GvTRXmQO0fsgFTIEhM5MEkoVsU
 U0VyNf/rp/QOKCrpBZaMapENcrGpmKv2U5uPQwPnQ0jNl2Ixp7Wq7xpVbMPB9JA9bdnlM4CFAHd
 A/oEsc7Ihe6HskrIrtsm+xziTjFUoPp3/qPyy7y1Y8cgMajjES9TZHKAH+G3KAOYHnvVDIklrCf
 Oo39RvqgS2nPGuakkWb1i4RR/D1NvAuJqMpZcsi+UinuTPgKlE3hn7Yg9fSdEnrH+ow4TeEV8lR
 qMQDd5+xskxvFw01WKi3VbpOeMhrKx+X1VQm1WvdjFN9sUlnpsTNUs5QsEmQFjxrE0Wx9kCe7v5
 6o=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

New ioctl to create a CDQ.

Creating a CDQ:
  Set the following memebers:
    * entry_nr: Number of CDQ entries
    * entry_nbytes: size in bytes of each CDQ entry
    * cqs: Create Queue Specific. Value depends on CDQ type
    * mos: Management Operation Specific. Value depends on CDQ type
    * cdqp_{offset,mask}: Location of CDQ Phase tag bit within an entry

Return:
    * cdq_id: The ID set by the controller for the created CDQ
    * read_fd: The file descriptor that can be used to read the CDQ

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 include/uapi/linux/nvme_ioctl.h | 12 ++++++++++++
 1 file changed, 12 insertions(+)

diff --git a/include/uapi/linux/nvme_ioctl.h b/include/uapi/linux/nvme_ioctl.h
index 2f76cba6716637baff53e167a6141b68420d75c3..dc434628acc8462877e774a1eec9242a5df8a08a 100644
--- a/include/uapi/linux/nvme_ioctl.h
+++ b/include/uapi/linux/nvme_ioctl.h
@@ -92,6 +92,17 @@ struct nvme_uring_cmd {
 	__u32   rsvd2;
 };
 
+struct nvme_cdq_cmd {
+	__u32	entry_nr;
+	__u32	entry_nbyte;
+	__u16	cdq_id;
+	__u16	cqs;
+	__u16	mos;
+	__u32	cdqp_offset;
+	__u32	cdqp_mask;
+	int	read_fd;
+};
+
 #define nvme_admin_cmd nvme_passthru_cmd
 
 #define NVME_IOCTL_ID		_IO('N', 0x40)
@@ -104,6 +115,7 @@ struct nvme_uring_cmd {
 #define NVME_IOCTL_ADMIN64_CMD	_IOWR('N', 0x47, struct nvme_passthru_cmd64)
 #define NVME_IOCTL_IO64_CMD	_IOWR('N', 0x48, struct nvme_passthru_cmd64)
 #define NVME_IOCTL_IO64_CMD_VEC	_IOWR('N', 0x49, struct nvme_passthru_cmd64)
+#define NVME_IOCTL_ADMIN_CDQ	_IOR('N', 0x50, struct nvme_cdq_cmd)
 
 /* io_uring async commands: */
 #define NVME_URING_CMD_IO	_IOWR('N', 0x80, struct nvme_uring_cmd)

-- 
2.47.2

