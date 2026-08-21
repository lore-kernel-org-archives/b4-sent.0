From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Thu, 20 Aug 2026 21:25:21 -0500
Subject: [PATCH v2 2/2] smb: client: reject a tree connect response whose
 byte count is too small
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260820-b4-disp-58f78a28-v2-2-1fb7a6cb1533@proton.me>
References: <20260820-b4-disp-58f78a28-v2-0-1fb7a6cb1533@proton.me>
In-Reply-To: <20260820-b4-disp-58f78a28-v2-0-1fb7a6cb1533@proton.me>
To: Steve French <sfrench@samba.org>
Cc: Paulo Alcantara <pc@manguebit.org>, Namjae Jeon <linkinjeon@kernel.org>, 
 Shyam Prasad N <sprasad@microsoft.com>, 
 Ronnie Sahlberg <ronniesahlberg@gmail.com>, 
 David Howells <dhowells@redhat.com>, Nathan Chancellor <nathan@kernel.org>, 
 Tom Talpey <tom@talpey.com>, llvm@lists.linux.dev, 
 Bharath SM <bharathsm@microsoft.com>, linux-cifs@vger.kernel.org, 
 linux-kernel@vger.kernel.org, samba-technical@lists.samba.org, 
 Jeff Layton <jlayton@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787279119; l=2384;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=jnZThUSNJS01CGO4lQzrO1j6YlnsYJLpzBtHx4exYdM=;
 b=w+/8Ihs+uz3rUM7EkxCLzcvtmL5f1IxPJsPnfuu+gT7d+3HRyjmDZeQJ/F9s+3IeFuOftzIIG
 oSnIGaY9WwNC07/DHz4+YkuMOblDdJgGv6XfZeMscePfWzv49dxgpjh
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

CIFSTCon() bounds its strnlen() over the byte area with the server's
ByteCount minus two, which for ByteCount 0 or 1 goes negative as an int
and converts to a huge size_t.  The later subtraction wraps the __u16
bytes_left, and that is what bounds cifs_strndup_from_utf16(): a bound of
up to 65535 against a ~16 KB cifs_req_poolp object runs off the end of the
slab object, and the bytes reach userspace through tcon->nativeFileSystem
in /proc/fs/cifs/DebugData.

Reject a byte area too small for what the parser consumes.  Two bytes is
the least the parse can consume, and no conformant response carries fewer
-- the Service field is at least "A:" and its NUL.

Fixes: cc20c031bb06 ("cifs: convert CIFSTCon to use new unicode helper functions")
Cc: stable@kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
 fs/smb/client/cifssmb.c | 6 ++++++
 fs/smb/client/trace.h   | 1 +
 2 files changed, 7 insertions(+)

diff --git a/fs/smb/client/cifssmb.c b/fs/smb/client/cifssmb.c
index 1f77512252e7..f5aad5f61dce 100644
--- a/fs/smb/client/cifssmb.c
+++ b/fs/smb/client/cifssmb.c
@@ -615,6 +615,11 @@ CIFSTCon(const unsigned int xid, struct cifs_ses *ses,
 		tcon->tid = smb_buffer_response->Tid;
 		bcc_ptr = pByteArea(smb_buffer_response);
 		bytes_left = get_bcc(smb_buffer_response);
+		if (bytes_left < 2) {
+			rc = smb_EIO2(smb_eio_trace_tcon_bcc_too_small,
+				      bytes_left, 2);
+			goto out;
+		}
 		length = strnlen(bcc_ptr, bytes_left - 2);
 		if (smb_buffer->Flags2 & SMBFLG2_UNICODE)
 			is_unicode = true;
@@ -670,6 +675,7 @@ CIFSTCon(const unsigned int xid, struct cifs_ses *ses,
 			reset_cifs_unix_caps(xid, tcon, NULL, NULL);
 		}
 	}
+out:
 	cifs_buf_release(smb_buffer);
 	return rc;
 }
diff --git a/fs/smb/client/trace.h b/fs/smb/client/trace.h
index 0a91d3aaa079..12241abb8e2e 100644
--- a/fs/smb/client/trace.h
+++ b/fs/smb/client/trace.h
@@ -133,6 +133,7 @@
 	EM(smb_eio_trace_sym_slash,			"sym_slash") \
 	EM(smb_eio_trace_sym_target_len,		"sym_target_len") \
 	EM(smb_eio_trace_symlink_file_size,		"symlink_file_size") \
+	EM(smb_eio_trace_tcon_bcc_too_small,		"tcon_bcc_too_small") \
 	EM(smb_eio_trace_tdis_in_reconnect,		"tdis_in_reconnect") \
 	EM(smb_eio_trace_tx_chained_async,		"tx_chained_async") \
 	EM(smb_eio_trace_tx_compress_failed,		"tx_compress_failed") \

-- 
2.55.0

