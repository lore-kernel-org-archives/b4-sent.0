From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Mon, 06 Jul 2026 02:28:42 -0500
Subject: [PATCH] scsi: ses: unregister the enclosure before freeing its
 device state
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260706-b4-disp-cf600574-v1-1-be4f324ff44c@proton.me>
X-B4-Tracking: v=1; b=H4sIAClZS2oC/x3MMQqAMAxA0atIZgNJsS16FXGoNmoWlRZEkN7d4
 viG/1/IklQyDM0LSW7Neh4V3Daw7OHYBDVWgyHjyJPDucOo+cJldUTWd2gC8+y5txwC1OxKsur
 zL8eplA/+QV2oYgAAAA==
To: "James E.J. Bottomley" <James.Bottomley@HansenPartnership.com>, 
 "Martin K. Petersen" <martin.petersen@oracle.com>
Cc: linux-scsi@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783322921; l=3846;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=PMMg+Li8yeHEw3N9pHy7QUwYed4TcTRn1gIA0LgYvfc=;
 b=tWXMaW7TvimfZET1YPjrntQSmxSu8TUnoDGKVbimt7TkGE/Kk8urXZBwQxA48jqN7qhAFeas5
 Gu67M8ZbzNFCnV+lwhWmz5aB40icFny2woAA/94FM1v5vAFHmnQ3/+D
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ses_intf_remove_enclosure() frees ses_dev and the page1/page2/page10
buffers it owns before calling enclosure_unregister().  Only
enclosure_unregister() tears down the component sysfs attributes -- which
drains any in-flight get or set access -- and repoints edev->cb at the null
callbacks, so between the frees and that call the attributes stay live over
freed memory.  A concurrent read or write of a component attribute then
dereferences the freed edev->scratch in ses_get_page2_descriptor() or
ses_show_id(): a use-after-free reachable while the enclosure is removed
(hot unplug or delete) and its sysfs is accessed.  The early
edev->scratch = NULL does not help -- ses_page2_supported() does not check
it, so it only turns the use-after-free into a NULL dereference.

Unregister first, then free.  Save the component scratch pointer while edev
is still alive (enclosure_unregister() drops the enclosure device), and
drop the now-redundant early scratch clear.

Fixes: 9927c68864e9 ("[SCSI] ses: add new Enclosure ULD")
Closes: https://sashiko.dev/#/patchset/20260706-b4-disp-29a05ca3-v1-1-49591f469f60@proton.me?part=1
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
Reproduced with an in-kernel KASAN litmus modelling the removal ordering
and the sysfs accessor: freeing ses_dev before enclosure_unregister() and
then dereferencing the freed scratch reports slab-use-after-free in
ses_get_page2_descriptor() (the page2 pointer, 16 bytes into the kmalloc-64
ses_device) and in ses_show_id() (the page1 pointer, offset 0); reordering
so enclosure_unregister() runs first is clean, as is the single-threaded
case.  Because the freed ses_device is a kmalloc-64 pointer carrier, a
reclaim of the freed slot turns ses_show_id()'s page1 read into an
arbitrary-read oracle and ses_get_page2_descriptor() -> ses_recv_diag()
into an arbitrary write.

Triggerable while a component sysfs attribute (fault/status/locate/active/
id) is read or written concurrently with enclosure removal (hot unplug or a
delete); no malicious device required.
---
 drivers/scsi/ses.c | 21 ++++++++++++++-------
 1 file changed, 14 insertions(+), 7 deletions(-)

diff --git a/drivers/scsi/ses.c b/drivers/scsi/ses.c
index 4c348645b04e..a3039a3ede56 100644
--- a/drivers/scsi/ses.c
+++ b/drivers/scsi/ses.c
@@ -862,6 +862,7 @@ static void ses_intf_remove_enclosure(struct scsi_device *sdev)
 {
 	struct enclosure_device *edev;
 	struct ses_device *ses_dev;
+	void *scomp;
 
 	/*  exact match to this enclosure */
 	edev = enclosure_find(&sdev->sdev_gendev, NULL);
@@ -869,18 +870,24 @@ static void ses_intf_remove_enclosure(struct scsi_device *sdev)
 		return;
 
 	ses_dev = edev->scratch;
-	edev->scratch = NULL;
+	scomp = edev->components ? edev->component[0].scratch : NULL;
+
+	/*
+	 * Unregister before freeing.  enclosure_unregister() tears down the
+	 * component sysfs attributes, draining any in-flight get or set access,
+	 * and points edev->cb at the null callbacks.  Freeing ses_dev and the
+	 * pages it references first leaves those attributes live over freed
+	 * memory, so a concurrent component-attribute access dereferences the
+	 * freed edev->scratch in ses_get_page2_descriptor() or ses_show_id().
+	 */
+	put_device(&edev->edev);
+	enclosure_unregister(edev);
 
 	kfree(ses_dev->page10);
 	kfree(ses_dev->page1);
 	kfree(ses_dev->page2);
 	kfree(ses_dev);
-
-	if (edev->components)
-		kfree(edev->component[0].scratch);
-
-	put_device(&edev->edev);
-	enclosure_unregister(edev);
+	kfree(scomp);
 }
 
 static void ses_intf_remove(struct device *cdev)

---
base-commit: dc59e4fea9d83f03bad6bddf3fa2e52491777482
change-id: 20260706-b4-disp-cf600574-2a11b71951aa

Best regards,
-- 
Bryam Vargas <hexlabsecurity@proton.me>

