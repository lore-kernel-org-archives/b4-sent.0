From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Fri, 21 Aug 2026 07:36:16 -0500
Subject: [PATCH v3] smb: client: reject a tree connect response whose byte
 count is too small
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260821-b4-disp-5297959d-v3-1-2f92f9abccee@proton.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ6CQAxA0auQrm0ChVHqVQwLZqZqWQCZIiEh3
 J1Rl2/x/w4mScXgXuyQZFXTacyoLwWEdz++BDVmA5V0LVuq0DcY1WZ0xDd2HDFSYGZPLnADOZu
 TPHX7LR/d3/bxg4Tl+4HjOAEz6Le/dAAAAA==
X-Change-ID: 20260821-b4-disp-5297959d-d2c999b25c94
To: Steve French <sfrench@samba.org>
Cc: Ronnie Sahlberg <ronniesahlberg@gmail.com>, 
 linux-kernel@vger.kernel.org, llvm@lists.linux.dev, 
 Tom Talpey <tom@talpey.com>, Jeff Layton <jlayton@kernel.org>, 
 Paulo Alcantara <pc@manguebit.org>, Bharath SM <bharathsm@microsoft.com>, 
 linux-cifs@vger.kernel.org, samba-technical@lists.samba.org, 
 Nathan Chancellor <nathan@kernel.org>, 
 Shyam Prasad N <sprasad@microsoft.com>, Namjae Jeon <linkinjeon@kernel.org>, 
 David Howells <dhowells@redhat.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787315776; l=5552;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=qMp2eGIfdAo+bcIGMz77Vp4+Kci5+wsU3Q1GbqELbBU=;
 b=qOELhIkMRoeI2pwEJydpD9ulO5fvo9/XTMPbyURhD//3w9xLChtQah1n+hXHdJIBta18TZaCh
 diMxC7w9aLRDv+kGRnmLFZQSWDI0+iLJJnb/rw3hyqEaDate121hYh0
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
the least it can consume, and no conformant response carries fewer.  The
new trace point is the 129th smb_eio_trace entry, which __mode(byte)
cannot represent, so the attribute goes with it.

Fixes: cc20c031bb06 ("cifs: convert CIFSTCon to use new unicode helper functions")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
v3: squashed into one patch. v2's 1/2 existed only so the new trace point
    would build -- the enum holds exactly 128 entries today and __mode(byte)
    houses them fine, so split off it fixed nothing and asked stable to
    backport a no-op. Its Fixes: f80ac7eda1cf went with it, and the enum
    change is one sentence of the body now. Cc: switched from
    stable@kernel.org to stable@vger.kernel.org, which is the delivering
    address for a public posting.
v2: https://lore.kernel.org/all/20260820-b4-disp-58f78a28-v2-0-1fb7a6cb1533@proton.me/
v1: https://lore.kernel.org/all/20260728-b4-disp-6b8e68d4-v1-1-e69277237297@proton.me/

Dropping __mode(byte) does not grow the record on x86_64: the field precedes
an unsigned long at offset 8 of struct trace_event_raw_smb3_eio, so sizeof()
stays 32 either way. Only clang notices the overflow -- it gives the enum a
signed underlying type and converts the 129th value to -128, which
CONFIG_WERROR=y turns into a build failure. gcc picks an unsigned underlying
type and says nothing, so on gcc the symptom would instead be those events
printing a raw number once the value stopped matching __print_symbolic().
The kernel test robot reported it there:
https://lore.kernel.org/oe-kbuild-all/202607290344.fvDmgRPA-lkp@intel.com/

Found with KMSAN. The out-of-bounds half is visible to KASAN once bytes_left
wraps, since the bound then exceeds the ~16 KB cifs_req_poolp object.

The server picks both ends of the walk. pByteArea() is buf + 35 + 2*WordCount
and CIFSTCon() never checks WordCount, so from WordCount 111 the byte area
starts past the 256 bytes header_assemble() clears. ByteCount 0 or 1 then
removes the bound. checkSMB() is not what saves this: the parse runs on the
request buffer, into which SendReceive() copies smbCalcSize() bytes, so an
honest bytes_left is what keeps the walk inside the copy.

Reproducer: a fake SMB1 server that answers negprot, completes
SESSION_SETUP_ANDX and replies to TREE_CONNECT_ANDX with WordCount 128 and
ByteCount 0.

  BUG: KMSAN: uninit-value in cifs_utf16_bytes+0x37e/0x400 [cifs]
   cifs_utf16_bytes+0x37e/0x400 [cifs]
   cifs_strndup_from_utf16+0x5c/0x210 [cifs]
   CIFSTCon+0x1102/0x1510 [cifs]
   cifs_setup_ipc+0x3b9/0xcf0 [cifs]

Stable trees older than v6.19 have neither smb_EIO2() nor the trace enum; the
backport there is the same guard with a plain rc = -EIO.

I did not add a WordCount check: once bytes_left is honest, the byte area is
always inside what SendReceive() copied. The guard sits after the tid store,
like the other failure paths here.
---
 fs/smb/client/cifssmb.c | 6 ++++++
 fs/smb/client/trace.h   | 3 ++-
 2 files changed, 8 insertions(+), 1 deletion(-)

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
index 5b21ad3c15fb..12241abb8e2e 100644
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
@@ -213,7 +214,7 @@
 #define EM(a, b) a,
 #define E_(a, b) a
 
-enum smb_eio_trace		{ smb_eio_traces } __mode(byte);
+enum smb_eio_trace		{ smb_eio_traces };
 enum smb3_rw_credits_trace	{ smb3_rw_credits_traces } __mode(byte);
 enum smb3_tcon_ref_trace	{ smb3_tcon_ref_traces } __mode(byte);
 

---
base-commit: c84d3e3130dfe1058cb27dc78e7ad8bd36f0545a
change-id: 20260821-b4-disp-5297959d-d2c999b25c94

Best regards,
--  
Bryam Vargas <hexlabsecurity@proton.me>

