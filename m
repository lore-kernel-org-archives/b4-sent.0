From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Mon, 27 Jul 2026 11:50:34 -0500
Subject: [PATCH] smb: client: bound the NTLMv2 blob to the SMB1
 session-setup byte area
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260727-b4-disp-f5a64b1f-v1-1-e7320e14c47e@proton.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMMQ7CMAxA0atUnrGUhDQRvQpiaBynmKGt4oKQq
 t6dAOMb/t9BuQorDN0OlV+isswN9tQB3cd5YpTcDM64YKKLmDxm0RVLPwafbMFIZ/KXHIwlDy1
 bKxd5/5bX29/6TA+m7fuB4/gATkLyH3QAAAA=
X-Change-ID: 20260727-b4-disp-f5a64b1f-7c3c49d601c4
To: Steve French <sfrench@samba.org>, Paulo Alcantara <pc@manguebit.org>
Cc: samba-technical@lists.samba.org, Bharath SM <bharathsm@microsoft.com>, 
 linux-kernel@vger.kernel.org, Shyam Prasad N <sprasad@microsoft.com>, 
 Ronnie Sahlberg <ronniesahlberg@gmail.com>, linux-cifs@vger.kernel.org, 
 Tom Talpey <tom@talpey.com>, David Howells <dhowells@redhat.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785171034; l=6740;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=iHowz74G+7jmAUYIwY9J5wUVN2lV0FgycIRv/ocYJA8=;
 b=t3MIoHckQzkvRYBwHFFaAgfTk3213yBl61E21wpCKSTr6KsjRlBp+0eBQe2tQOZHuh/T6asSC
 IAt+Zg1WH9HAjt7CXzZqbGAF298ep1LPf9gNboJDejQHZf6oCBAhBql
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

sess_auth_ntlmv2() copies the NTLMv2 response blob into the fixed
2000-byte byte area that sess_alloc_buffer() allocates, without checking
that it fits.  Since commit 33cfdd726381 ("smb: client: fix session setup
against servers that require SPN") ses->auth_key.len carries the SPN, so
it grows with strlen(server->hostname), and extract_hostname() does not
cap that.  A hostname of a few hundred bytes overflows the byte area, and
server->hostname can come from a DFS referral target by way of
__reconnect_target_locked(), i.e. from the server.

Reject the session setup when the blob does not fit.  The SMB2/3 consumer
of auth_key.len is unaffected: size_of_ntlmssp_blob() sizes its allocation
from it.  A hostname at the 253-byte DNS limit needs 590 of the 775
available.

Fixes: 33cfdd726381 ("smb: client: fix session setup against servers that require SPN")
Cc: stable@kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
Reproduced on v7.2-rc1 with KASAN and CONFIG_CIFS_ALLOW_INSECURE_LEGACY=y,
against a fake SMB1 server whose only job is to answer negprot with
EncryptionKeyLength == 8 and no CAP_EXTENDED_SECURITY.  That picks
CIFS_NEGFLAVOR_UNENCAP, which routes the session setup through
sess_auth_ntlmv2().  The server never has to answer the session setup itself:
the copy happens while the client builds the request, before
sess_sendreceive().

Reproducer.  A UNC whose hostname is long enough that the SPN pushes
auth_key.len past the byte area:

  mount(2)("//<2000 x 'h'>/share", "/mnt", "cifs", 0,
           "vers=1.0,sec=ntlmv2,user=u,password=p,ip=127.0.0.1,port=4445")

mount(8) will not deliver that.  It prefers the new mount API, where
fsconfig(FSCONFIG_SET_STRING) truncates the source at 255 bytes
(strndup_user(_value, 256)).  copy_mount_string() takes PATH_MAX, so the
reproducer calls mount(2) directly.

A/B on v7.2-rc1, all three arms in one boot with kasan.fault=report, the clean
ones first since KASAN only reports once per boot:

  3-char hostname, unpatched:     memcpy of 90 bytes, clean
  2000-char hostname, patched:    "NTLMv2 response blob too long (4084)",
                                  mount fails -EIO, clean
  2000-char hostname, unpatched:

    BUG: KASAN: slab-out-of-bounds in sess_auth_ntlmv2+0x3d1/0xee0 [cifs]
    Write of size 4084 at addr ffff88810d921000 by task smb1_mount/1121
     __asan_memcpy+0x3c/0x60
     sess_auth_ntlmv2+0x3d1/0xee0 [cifs]
     CIFS_SessSetup+0x1bf/0x350 [cifs]
     cifs_setup_session+0x248/0xaf0 [cifs]
     cifs_get_smb_ses+0xf46/0x17b0 [cifs]
     dfs_mount_share+0x1e5/0x21f0 [cifs]
    Allocated by task 1121:
     __kmalloc_cache_noprof+0x153/0x360
     sess_alloc_buffer+0x176/0x2e0 [cifs]
     sess_auth_ntlmv2+0xc1/0xee0 [cifs]
    The buggy address is located 0 bytes inside of
     allocated 2000-byte region [ffff88810d921000, ffff88810d9217d0)

auth_key.len there is CIFS_SESS_KEY_SIZE + sizeof(struct ntlmv2_resp) + the
AV-pair blob + 2 * (5 + strlen(hostname)) + the two trailing AV pairs, so 4100
for that hostname and the default WORKGROUP domain, and a copy of 4084: 2084
past the end.  It does not stop at the blob either.  The strings that
unicode_ssetup_strings() appends afterwards land on the next object, and the
following _raw_spin_lock() takes a GP fault on 0x2000530046005630, which is
UTF-16 from that tail.

The other two writers of that byte area stay inside it.  sess_auth_kerberos()
and _sess_auth_rawntlmssp_assemble_req() put only the OS and domain strings
there -- the SPNEGO blob travels in iov[1] by pointer, uncopied -- which caps
them near 711 bytes.  Every other consumer of auth_key.len sizes its allocation
from it: size_of_ntlmssp_blob() on the SMB2/3 side, and the kmemdup() in
sess_establish_session().

Nothing that works today stops working.  The other way to reach the limit is a
256-byte domain next to a 253-byte hostname, needing 1084 bytes; but that pair
already writes 2309 into the 2000-byte area on current mainline, so it is
broken before this patch rather than by it.

The DFS route is by inspection, not reproduced.  __reconnect_target_locked()
replaces server->hostname with extract_hostname(<referral target>), and the
reconn_set_ipaddr_from_hostname() return value is logged and then overwritten
by generic_ip_connect(), so a hostname that does not resolve still reaches
session setup.

33cfdd726381 first appeared in v6.17-rc1.

Growing the byte area instead would also work, but put_bcc() puts that count on
the wire as a __u16, so it only moves the ceiling.  Happy to switch if you'd
rather not fail the mount.
---
 fs/smb/client/smb1session.c | 27 +++++++++++++++++++++++++--
 1 file changed, 25 insertions(+), 2 deletions(-)

diff --git a/fs/smb/client/smb1session.c b/fs/smb/client/smb1session.c
index 83bfbf0c068e..d610a32cc4f0 100644
--- a/fs/smb/client/smb1session.c
+++ b/fs/smb/client/smb1session.c
@@ -16,6 +16,22 @@
 #include "cifs_unicode.h"
 #include "cifs_debug.h"
 
+/* byte area sess_alloc_buffer() hands to a session setup request */
+#define SESS_SETUP_BYTE_AREA	2000
+
+/* what unicode_ssetup_strings() appends after the blob: alignment pad,
+ * user, domain, and three cifs_strtoUTF16() calls capped at 32 characters
+ */
+#define SESS_SETUP_STRINGS_MAX					\
+	(1							\
+	 + 2 * CIFS_MAX_USERNAME_LEN + 2			\
+	 + 2 * CIFS_MAX_DOMAINNAME_LEN + 2			\
+	 + 2 * 32 + 2 * 32 + 2					\
+	 + 2 * 32 + 2)
+
+#define SESS_SETUP_BLOB_MAX					\
+	(SESS_SETUP_BYTE_AREA - SESS_SETUP_STRINGS_MAX)
+
 struct sess_data {
 	unsigned int xid;
 	struct cifs_ses *ses;
@@ -330,8 +346,7 @@ sess_alloc_buffer(struct sess_data *sess_data, int wct)
 	 */
 	sess_data->buf0_type = CIFS_SMALL_BUFFER;
 
-	/* 2000 big enough to fit max user, domain, NOS name etc. */
-	sess_data->iov[2].iov_base = kmalloc(2000, GFP_KERNEL);
+	sess_data->iov[2].iov_base = kmalloc(SESS_SETUP_BYTE_AREA, GFP_KERNEL);
 	if (!sess_data->iov[2].iov_base) {
 		rc = -ENOMEM;
 		goto out_free_smb_buf;
@@ -449,6 +464,14 @@ sess_auth_ntlmv2(struct sess_data *sess_data)
 			goto out;
 		}
 
+		if (ses->auth_key.len - CIFS_SESS_KEY_SIZE >
+		    SESS_SETUP_BLOB_MAX) {
+			cifs_dbg(VFS, "NTLMv2 response blob too long (%u)\n",
+				 ses->auth_key.len - CIFS_SESS_KEY_SIZE);
+			rc = -EIO;
+			goto out;
+		}
+
 		memcpy(bcc_ptr, ses->auth_key.response + CIFS_SESS_KEY_SIZE,
 				ses->auth_key.len - CIFS_SESS_KEY_SIZE);
 		bcc_ptr += ses->auth_key.len - CIFS_SESS_KEY_SIZE;

---
base-commit: 4235cb24ec1e8e96843f3671ba4da2a6ccca2c7b
change-id: 20260727-b4-disp-f5a64b1f-7c3c49d601c4

Best regards,
--  
Bryam Vargas <hexlabsecurity@proton.me>

