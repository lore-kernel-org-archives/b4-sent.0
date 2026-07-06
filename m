From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Mon, 06 Jul 2026 00:46:08 -0500
Subject: [PATCH] scsi: ses: bound the page 2 descriptor walk to the page 2
 buffer
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260706-b4-disp-29a05ca3-v1-1-49591f469f60@proton.me>
X-B4-Tracking: v=1; b=H4sIAB9BS2oC/x3MTQqAIBBA4avErBvwpwy7SrQwnWo2FgoRiHdPW
 n6L9wpkSkwZ5q5AooczX7FB9h3408WDkEMzKKGMmITBbcDA+UZlnRi90+jlTpMP1ljtoGV3op3
 ff7mstX74FkkRYgAAAA==
To: "Martin K. Petersen" <martin.petersen@oracle.com>, 
 "James E.J. Bottomley" <James.Bottomley@HansenPartnership.com>
Cc: linux-scsi@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783316767; l=4392;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=gjPzPrt4L5sJeST+L+d9qWN0U53/IPRJX5pC82X/+Y4=;
 b=jP3yR3xiLoGvEWZkZj/2svwNc7kIOruob3tPtV65XQaUmQkolmFovFgZ+cdRrh2QL5/+TvqIB
 HaoB9itfplEDNRCZ8qSyECjjFOGlXfkq4u5OPbY+Z5Vt6WVkC2D5wWp
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ses_get_page2_descriptor() and ses_set_page2_descriptor() walk the
enclosure status descriptors by advancing desc_ptr four bytes per page 1
element without bounding it against the page 2 allocation.  The
descriptor count comes from page 1 while page 2 is a separately sized
diagnostic page, both supplied by the enclosure device; a device that
reports more descriptors than page 2 can hold walks desc_ptr past the
buffer.  The get path then dereferences it, a four-byte out-of-bounds
heap read reachable through the component sysfs attributes, and the set
path writes four bytes past the buffer.

Stop each walk once the next descriptor would extend past the end of
page 2: the get path returns NULL, which its callers already handle, and
the set path stops before the copy.  Well-formed enclosures are
unaffected.  The unbounded walk was flagged by the Sashiko AI review
(https://sashiko.dev) of the page 2 header length fix.

Fixes: 9927c68864e9 ("[SCSI] ses: add new Enclosure ULD")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
Reproduced with an in-kernel KASAN module that models the page 2 walk: a
page 1 declaring one component with an 8-byte page 2 makes the first
descriptor land at page2+12, four bytes past the kmalloc-8 object.  KASAN
reports slab-out-of-bounds Write (ses_set_page2_descriptor) and Read
(ses_get_page2_descriptor); the read returns adjacent heap rather than the
zeroed in-bounds bytes.  With the patch both walks stop before that access,
and a page 2 large enough for the page 1 descriptors is unchanged.

The pages are only device-supplied, so this needs a malicious or
malfunctioning SES enclosure; the write path additionally needs a
privileged write to the component sysfs attributes.

There is a separate, already-posted fix on this file for the page 2
status-page-header underflow ("scsi: ses: skip an enclosure status page
shorter than its header").  This one is independent -- the hunks do not
overlap and it applies on v7.2-rc1 either way.
---
 drivers/scsi/ses.c | 13 +++++++++++++
 1 file changed, 13 insertions(+)

diff --git a/drivers/scsi/ses.c b/drivers/scsi/ses.c
index 4c348645b04e..7e9c33809131 100644
--- a/drivers/scsi/ses.c
+++ b/drivers/scsi/ses.c
@@ -184,12 +184,21 @@ static int ses_set_page2_descriptor(struct enclosure_device *edev,
 	struct ses_device *ses_dev = edev->scratch;
 	unsigned char *type_ptr = ses_dev->page1_types;
 	unsigned char *desc_ptr = ses_dev->page2 + 8;
+	unsigned char *page2_end = ses_dev->page2 + ses_dev->page2_len;
 
 	/* Clear everything */
 	memset(desc_ptr, 0, ses_dev->page2_len - 8);
 	for (i = 0; i < ses_dev->page1_num_types; i++, type_ptr += 4) {
 		for (j = 0; j < type_ptr[1]; j++) {
 			desc_ptr += 4;
+			/*
+			 * The descriptor count comes from page 1 while page 2
+			 * is a separately sized diagnostic page; a device that
+			 * reports more descriptors than page 2 can hold would
+			 * walk desc_ptr past the buffer, so stop here.
+			 */
+			if (desc_ptr + 4 > page2_end)
+				goto out;
 			if (type_ptr[0] != ENCLOSURE_COMPONENT_DEVICE &&
 			    type_ptr[0] != ENCLOSURE_COMPONENT_ARRAY_DEVICE)
 				continue;
@@ -203,6 +212,7 @@ static int ses_set_page2_descriptor(struct enclosure_device *edev,
 		}
 	}
 
+out:
 	return ses_send_diag(sdev, 2, ses_dev->page2, ses_dev->page2_len);
 }
 
@@ -214,6 +224,7 @@ static unsigned char *ses_get_page2_descriptor(struct enclosure_device *edev,
 	struct ses_device *ses_dev = edev->scratch;
 	unsigned char *type_ptr = ses_dev->page1_types;
 	unsigned char *desc_ptr = ses_dev->page2 + 8;
+	unsigned char *page2_end = ses_dev->page2 + ses_dev->page2_len;
 
 	if (ses_recv_diag(sdev, 2, ses_dev->page2, ses_dev->page2_len))
 		return NULL;
@@ -221,6 +232,8 @@ static unsigned char *ses_get_page2_descriptor(struct enclosure_device *edev,
 	for (i = 0; i < ses_dev->page1_num_types; i++, type_ptr += 4) {
 		for (j = 0; j < type_ptr[1]; j++) {
 			desc_ptr += 4;
+			if (desc_ptr + 4 > page2_end)
+				return NULL;
 			if (type_ptr[0] != ENCLOSURE_COMPONENT_DEVICE &&
 			    type_ptr[0] != ENCLOSURE_COMPONENT_ARRAY_DEVICE)
 				continue;

---
base-commit: dc59e4fea9d83f03bad6bddf3fa2e52491777482
change-id: 20260706-b4-disp-29a05ca3-c1fe7cd9693a

Best regards,
-- 
Bryam Vargas <hexlabsecurity@proton.me>

