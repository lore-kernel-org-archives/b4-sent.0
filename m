From: Dave Marquardt <davemarq@linux.ibm.com>
Date: Tue, 24 Mar 2026 11:56:25 -0500
Subject: [PATCH] scsi: fix typo in fc_els.h
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260324-fix-typo-v1-1-601f4fde35bc@linux.ibm.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMTQ5AMBAG0Ks0s9ak2pJwFbGgHYwFTYuQxt0Vy
 5fvJ0JATxigZhE8HhRoXRLyjIGZumVETjYZpJClUFLzgU6+XW7lhUIpVKVR2RJS3XlM2XfVtL/
 D3s9otncP9/0AKDPXhGwAAAA=
X-Change-ID: 20260324-fix-typo-53e20394e3d6
To: Hannes Reinecke <hare@suse.de>, 
 "James E.J. Bottomley" <James.Bottomley@HansenPartnership.com>, 
 "Martin K. Petersen" <martin.petersen@oracle.com>
Cc: linux-scsi@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dave Marquardt <davemarq@linux.ibm.com>
X-Mailer: b4 0.15.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1774371393; l=950;
 i=davemarq@linux.ibm.com; s=20260216; h=from:subject:message-id;
 bh=4bBSPr33ggF6ln+jKg0/Xc7FNaPHwzq2SefmglZHvvY=;
 b=4z5IUxOzgYIXHFEbUgF6NgeEYqU+atJYRwJl9jnSo7F9OBEz0ukgME9p7nqkPZxSwphA6vnY1
 QDk2Kg0y3bUBd50SgBLstYM2IiQfmVHseLpow5QCjydx9WXYpmccKRO
X-Developer-Key: i=davemarq@linux.ibm.com; a=ed25519;
 pk=vy0/nfobrje6EqZxuyw6a3ZstytG8WK2vf5Y3xtGrEg=
X-Endpoint-Received: by B4 Relay for davemarq@linux.ibm.com/20260216 with auth_id=689
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Changed "caause" to "cause".

---
Fixed spelling error in fe_els.h.

Signed-off-by: Dave Marquardt <davemarq@linux.ibm.com>
---
 include/uapi/scsi/fc/fc_els.h | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/include/uapi/scsi/fc/fc_els.h b/include/uapi/scsi/fc/fc_els.h
index 019096beb179..dca6a28f4e86 100644
--- a/include/uapi/scsi/fc/fc_els.h
+++ b/include/uapi/scsi/fc/fc_els.h
@@ -1030,7 +1030,7 @@ struct fc_fn_li_desc {
 					 */
 	__be32		event_count;	/* minimum number of event
 					 * occurrences during the event
-					 * threshold to caause the LI event
+					 * threshold to cause the LI event
 					 */
 	__be32		pname_count;	/* number of portname_list elements */
 	__be64		pname_list[];	/* list of N_Port_Names accessible

---
base-commit: 01f784fc9d0ab2a6dac45ee443620e517cb2a19b
change-id: 20260324-fix-typo-53e20394e3d6

Best regards,
--  
Dave Marquardt <davemarq@linux.ibm.com>

