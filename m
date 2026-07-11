From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Sat, 11 Jul 2026 02:44:27 -0500
Subject: [PATCH] scsi: ses: validate the page 1 geometry before walking it
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260711-b4-disp-26cc3226-v1-1-e04c11c88996@proton.me>
X-B4-Tracking: v=1; b=H4sIAFr0UWoC/x3MMQqAMAxA0atIZgNNlIheRRy0jZpFpQURine3O
 L7h/wxJo2mCocoQ9bZk51FAdQV+n49N0UIxsGNxHREuLQZLF7J43zALck+zUivCQaFkV9TVnn8
 5Tu/7AfODb35iAAAA
To: "James E.J. Bottomley" <James.Bottomley@HansenPartnership.com>, 
 "Martin K. Petersen" <martin.petersen@oracle.com>
Cc: linux-scsi@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783755866; l=2966;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=yJwlxB420glQfMDCa0LhYH0dnfguuLnK0jmLkeHB6U0=;
 b=dRjIpDzdZHy5uPXSKKwGbrZNr5NMATAnPwye72vaKPP/9MH90riPPjTNOJuaMQE0nX+ejtwGa
 h1oP/sDebH1C+toh0aBcLIr93rx2yPdFTHxk0M3mbqaIWlWX8obm+q1
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ses_intf_add() stores the enclosure's page 1 type-descriptor pointer and
count (page1_types, page1_num_types) without bounding them against the
page 1 buffer.  The page 2 descriptor walks, ses_enclosure_data_process()
and the logical-id read in ses_show_id() all iterate or index with those
device-supplied values.  An enclosure that reports a short page 1 with an
inflated type count, or one too short for its logical id, makes those
reads run past the page 1 allocation -- an out-of-bounds read of adjacent
slab, some of which ses_show_id() hands back to user space.

Validate the page 1 geometry where it is parsed and reject a page too
short for its logical id or declaring more type descriptors than it
carries.  Conforming enclosures are unaffected.

Fixes: 9927c68864e9 ("[SCSI] ses: add new Enclosure ULD")
Closes: https://sashiko.dev/#/patchset/20260706-b4-disp-29a05ca3-v1-1-49591f469f60@proton.me?part=1
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
Verified with an in-kernel KASAN model (7.2.0-rc1) that replays each
accessor over a real kmalloc'd page 1:
  - ses_show_id() read (page1+12, 8 bytes) over a 12-byte page 1
    -> BUG: KASAN: slab-out-of-bounds READ; a validated page 1 is clean.
  - a type_ptr walk with an inflated page1_num_types over a short page 1
    -> BUG: KASAN: slab-out-of-bounds READ; the geometry check stops it.
  - a conforming page 1 -> clean.
Reproducer available on request.
---
 drivers/scsi/ses.c | 16 ++++++++++++++++
 1 file changed, 16 insertions(+)

diff --git a/drivers/scsi/ses.c b/drivers/scsi/ses.c
index 4c348645b04e..bbd8ff13cb2a 100644
--- a/drivers/scsi/ses.c
+++ b/drivers/scsi/ses.c
@@ -750,6 +750,22 @@ static int ses_intf_add(struct device *cdev)
 	ses_dev->page1_types = type_ptr;
 	ses_dev->page1_num_types = types;
 
+	/*
+	 * Validate the device-reported page 1 geometry once, here, before the
+	 * accessors walk it.  page1_types and page1_num_types come straight from
+	 * the enclosure, and the page 2 descriptor walks (ses_get_page2_descriptor(),
+	 * ses_set_page2_descriptor()), ses_enclosure_data_process() and the
+	 * logical-id read in ses_show_id() all trust them.  A page 1 shorter than
+	 * its logical-id field, or one that declares more type descriptors than it
+	 * carries, would make those reads run past the page 1 buffer.
+	 */
+	if (len < 8 + 4 + (int)sizeof(u64) ||
+	    ses_dev->page1_types > buf + len ||
+	    ses_dev->page1_num_types > (buf + len - ses_dev->page1_types) / 4) {
+		err = -EINVAL;
+		goto err_free;
+	}
+
 	for (i = 0; i < types && type_ptr < buf + len; i++, type_ptr += 4) {
 		if (type_ptr[0] == ENCLOSURE_COMPONENT_DEVICE ||
 		    type_ptr[0] == ENCLOSURE_COMPONENT_ARRAY_DEVICE)

---
base-commit: dd3210c47e8d3ac6b4e9141fc68acc03b38c0ba3
change-id: 20260711-b4-disp-26cc3226-291ae14662de

Best regards,
-- 
Bryam Vargas <hexlabsecurity@proton.me>

