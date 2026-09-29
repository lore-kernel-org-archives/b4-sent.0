From: Ahmed Abdelhaleem Ahmed <ahmedhal@gmail.com>
Date: Tue, 29 Sep 2026 03:09:37 +0000
Subject: [PATCH v2] scsi: ch: Do not keep references to data transfer
 element devices
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260929-ch-dt-leak-v2-1-ddda8d635dca@gmail.com>
X-B4-Tracking: v=1; b=H4sIAPAru2oC/3XMyw6CMBCF4Vchs3YMnZAGXfkexkUvUxil1LRIT
 AjvLuja5Z+c8y1QOAsXOFcLZJ6lSBq3oEMFrjdjxyh+a6CadH0iQtejn3Bg80BHqlVW++BNC9v
 hmTnI+4tdb78uL3tnN+3Cvgg5RZz6zOYvOitUSJa4qW1QmppLF40MR5cirOsHHaOV3LAAAAA=
X-Change-ID: 20260922-ch-dt-leak-c2181b6dfda8
To: "James E.J. Bottomley" <James.Bottomley@HansenPartnership.com>, 
 "Martin K. Petersen" <mkp@kernel.org>
Cc: linux-scsi@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Laurence Oberman <loberman@redhat.com>, 
 Ahmed Abdelhaleem Ahmed <ahmedhal@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790651376; l=4827;
 i=ahmedhal@gmail.com; s=20260922; h=from:subject:message-id;
 bh=AkA4AXhAlzgacB7N6QIzGWHRluIdshbkoX1ojn/EHC8=;
 b=LFo/bfT7N4n91cGSIgh47ytPvB4SzPw0X+Qw/Q3g8ZRb+n2gp/KMlXw+Xmqq9eJEl66eQ947O
 98c6Te7j5zKDpGLTg7vsI1Ou1Eaxpm8Bkytvoq5Nwk83NpZuSj76cUU
X-Developer-Key: i=ahmedhal@gmail.com; a=ed25519;
 pk=UEFWTgykG696wvaHZw+52zx9UkpJCW3L3hvdRay28Fo=
X-Endpoint-Received: by B4 Relay for ahmedhal@gmail.com/20260922 with auth_id=1049
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ch_readconfig() looks up the scsi_device of every data transfer element
whose SCSI id the changer reports in READ ELEMENT STATUS, and stores it
in ch->dt[]. scsi_device_lookup() takes a reference, and nothing ever
drops it: ch_destroy() frees the array with kfree(). ch->dt[] is read
nowhere else - it only supplies the vendor, model and revision printed
in the same loop.

Once such a drive is removed, its scsi_device can never be released. It
stays on the host's device list at its address, so a new device there is
refused by anything that walks the list - target_core_pscsi reports
"scsi_device_get() failed for H:C:T:L" - and the low-level driver's
module can no longer be unloaded. Only a reboot recovers.

It shows with any changer that reports its drives' ids; with the mhvtl
virtual library (IBM 3573-TL personality), each create and remove of a
library with four drives leaves four references behind, counted by the
module's use count in lsmod. With ch not bound the count is unchanged,
and with this patch applied it is unchanged too.

Drop the reference as soon as the name has been printed, and remove the
now unused dt[] array. That also removes the array leaked when
ch_probe() fails after ch_readconfig().

The same leak was reported with an RFC patch in 2022, which was not
merged.

Fixes: daa6eda65a53 ("[SCSI] add scsi changer driver")
Cc: stable@vger.kernel.org
Link: https://lore.kernel.org/linux-scsi/20220719075442.6215-1-yanghao_ht@163.com/
Reviewed-by: Laurence Oberman <loberman@redhat.com>
Signed-off-by: Ahmed Abdelhaleem Ahmed <ahmedhal@gmail.com>
---
v2: corrected the Fixes: tag. v1 named 1da177e4c3f4 ("Linux-2.6.12-rc2"),
    the initial git import, which is not where this was introduced - the ch
    driver was added later, by daa6eda65a53 ("[SCSI] add scsi changer
    driver"). That tag is what the stable maintainers read to decide how far
    back to backport, so it is worth getting right.

    A reply was sent to the v1 thread with the correction, but a reply can
    only add a trailer, never replace one, so the thread carries both. This
    v2 exists to leave exactly one.

    Laurence Oberman's Reviewed-by from the v1 thread is carried forward.

    The code is unchanged from v1 - the same nine lines.
---
 drivers/scsi/ch.c | 29 +++++++++--------------------
 1 file changed, 9 insertions(+), 20 deletions(-)

diff --git a/drivers/scsi/ch.c b/drivers/scsi/ch.c
index 87e51e50a..b2c9fb71c 100644
--- a/drivers/scsi/ch.c
+++ b/drivers/scsi/ch.c
@@ -112,7 +112,6 @@ typedef struct {
 	int                 minor;
 	char                name[8];
 	struct scsi_device  *device;
-	struct scsi_device  **dt;        /* ptrs to data transfer elements */
 	u_int               firsts[CH_TYPES];
 	u_int               counts[CH_TYPES];
 	u_int		    voltags;
@@ -354,15 +353,10 @@ ch_readconfig(scsi_changer *ch)
 			vendor_labels[i]);
 	}
 
-	/* look up the devices of the data transfer elements */
-	ch->dt = kzalloc_objs(*ch->dt, ch->counts[CHET_DT]);
-
-	if (!ch->dt) {
-		kfree(buffer);
-		return -ENOMEM;
-	}
-
+	/* report the devices of the data transfer elements */
 	for (elem = 0; elem < ch->counts[CHET_DT]; elem++) {
+		struct scsi_device *sdev;
+
 		id  = -1;
 		lun = 0;
 		if (elem < CH_DT_MAX  &&  -1 != dt_id[elem]) {
@@ -378,10 +372,8 @@ ch_readconfig(scsi_changer *ch)
 			VPRINTK(KERN_INFO, "dt 0x%x: ",elem+ch->firsts[CHET_DT]);
 			if (data[6] & 0x80) {
 				VPRINTK(KERN_CONT, "not this SCSI bus\n");
-				ch->dt[elem] = NULL;
 			} else if (0 == (data[6] & 0x30)) {
 				VPRINTK(KERN_CONT, "ID/LUN unknown\n");
-				ch->dt[elem] = NULL;
 			} else {
 				id  = ch->device->id;
 				lun = 0;
@@ -391,18 +383,16 @@ ch_readconfig(scsi_changer *ch)
 		}
 		if (-1 != id) {
 			VPRINTK(KERN_CONT, "ID %i, LUN %i, ",id,lun);
-			ch->dt[elem] =
-				scsi_device_lookup(ch->device->host,
-						   ch->device->channel,
-						   id,lun);
-			if (!ch->dt[elem]) {
+			sdev = scsi_device_lookup(ch->device->host,
+						  ch->device->channel,
+						  id, lun);
+			if (!sdev) {
 				/* should not happen */
 				VPRINTK(KERN_CONT, "Huh? device not found!\n");
 			} else {
 				VPRINTK(KERN_CONT, "name: %8.8s %16.16s %4.4s\n",
-					ch->dt[elem]->vendor,
-					ch->dt[elem]->model,
-					ch->dt[elem]->rev);
+					sdev->vendor, sdev->model, sdev->rev);
+				scsi_device_put(sdev);
 			}
 		}
 	}
@@ -566,7 +556,6 @@ static void ch_destroy(struct kref *ref)
 	scsi_changer *ch = container_of(ref, scsi_changer, ref);
 
 	ch->device = NULL;
-	kfree(ch->dt);
 	kfree(ch);
 }
 

---
base-commit: f09d2c7485b32adb82336d0d748935c8237a649e
change-id: 20260922-ch-dt-leak-c2181b6dfda8

Best regards,
--  
Ahmed Abdelhaleem Ahmed <ahmedhal@gmail.com>

