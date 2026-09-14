From: Mark Amirkan <markdamirkan@gmail.com>
Date: Sun, 13 Sep 2026 17:15:52 -0700
Subject: [PATCH] HID: bpf: reject oversized device events before copying
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260913-b4-send-hid-bpf-event-bounds-v1-1-614fb56a0635@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMTQ6CMBAG0KuQWTtJi41/VzEsnPZDxkUhHSAmh
 Ltbdfk2byNDURjdmo0KVjUdc4U/NBSHR36CNVVT69qTu/ojS2BDTjxoYpl6xoo8s4xLTsYhOVz
 82UVIoFpMBb2+f/29+9sWeSHO35P2/QN9qlUagAAAAA==
X-Change-ID: 20260913-b4-send-hid-bpf-event-bounds-4d0e8170ceb4
To: Jiri Kosina <jikos@kernel.org>, Benjamin Tissoires <bentiss@kernel.org>
Cc: linux-input@vger.kernel.org, linux-kernel@vger.kernel.org, 
 bpf@vger.kernel.org, stable@vger.kernel.org, 
 Mark Amirkan <markdamirkan@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789344983; l=2003;
 i=markdamirkan@gmail.com; s=pscsi-20260818; h=from:subject:message-id;
 bh=Ia7zUbF957KqlNGyqwYypZyyCwU42rijJnHEBVEKNhk=;
 b=/ogx9vdoMRR7AlMAI52cVD4nGYJ2/YRgv9iUk25VVCPdxw4rOqGtU80OanuLdFs4XcUedo0at
 v1g/vX0R8LPDexYwhHBG8kYNxIxHsLcWdv5W7A4/Yt3mRET+GkVUpCJ
X-Developer-Key: i=markdamirkan@gmail.com; a=ed25519;
 pk=/wb49ibt4gZFDncmhFQBYtjPvzT1tfJtvK4Mqt1P2Wc=
X-Endpoint-Received: by B4 Relay for markdamirkan@gmail.com/pscsi-20260818 with auth_id=961
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

HID-BPF allocates its device-event buffer from the largest report in the
device's parsed report descriptor.  dispatch_hid_bpf_device_event() then
copies the transport-provided report into that buffer before checking its
size.

An input report larger than the allocated event buffer therefore causes
a heap out-of-bounds write when a device-event program is attached.  The
later check of the BPF program's return value cannot prevent the initial
copy.

Reject reports that exceed either the transport buffer or the persistent
HID-BPF event buffer before clearing or copying the data.

With a 64-byte event allocation, a same-file KUnit test produced a
one-byte KASAN out-of-bounds write for a 65-byte report in three runs.
The 64-byte boundary remained clean.  After this change, both cases were
clean in three runs and the oversized report returned -EINVAL.  The test
exercised the production dispatch function but not the complete UHID and
BPF attachment path.

Fixes: 658ee5a64fcf ("HID: bpf: allocate data memory for device_event BPF programs")
Cc: stable@vger.kernel.org
Assisted-by: LLM Symbolic
Signed-off-by: Mark Amirkan <markdamirkan@gmail.com>
---
 drivers/hid/bpf/hid_bpf_dispatch.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/drivers/hid/bpf/hid_bpf_dispatch.c b/drivers/hid/bpf/hid_bpf_dispatch.c
index 536f6d01fd..06ba833eb9 100644
--- a/drivers/hid/bpf/hid_bpf_dispatch.c
+++ b/drivers/hid/bpf/hid_bpf_dispatch.c
@@ -50,6 +50,9 @@ dispatch_hid_bpf_device_event(struct hid_device *hdev, enum hid_report_type type
 	if (!hdev->bpf.device_data)
 		return data;
 
+	if (*size > *buf_size || *size > ctx_kern.ctx.allocated_size)
+		return ERR_PTR(-EINVAL);
+
 	memset(ctx_kern.data, 0, hdev->bpf.allocated_data);
 	memcpy(ctx_kern.data, data, *size);
 

---
base-commit: 9cdc7e6dc7a99ad7311ad5e7c145f2b9ce4e24b0
change-id: 20260913-b4-send-hid-bpf-event-bounds-4d0e8170ceb4

Best regards,
--  
Mark Amirkan <markdamirkan@gmail.com>

