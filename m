From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Tue, 28 Jul 2026 13:06:22 -0500
Subject: [PATCH] smb: client: reject a tree connect response whose byte
 count is too small
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260728-b4-disp-6b8e68d4-v1-1-e69277237297@proton.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ6CMBBG4auQWTtJmWAtXsW4oO2PjgskHTUkh
 LtTdfkt3lvJUBRG52algo+aPqeK9tBQug/TDay5msSJdycJHDvOajP7GOBD7ngc5IjW9akXUM3
 mglGX3/Jy/dve8YH0+n5o23aNeWrPdAAAAA==
X-Change-ID: 20260728-b4-disp-6b8e68d4-fa25e109c92e
To: Steve French <sfrench@samba.org>, Paulo Alcantara <pc@manguebit.org>
Cc: Shyam Prasad N <sprasad@microsoft.com>, samba-technical@lists.samba.org, 
 Ronnie Sahlberg <ronniesahlberg@gmail.com>, 
 Jeff Layton <jlayton@kernel.org>, linux-cifs@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Tom Talpey <tom@talpey.com>, 
 Bharath SM <bharathsm@microsoft.com>, David Howells <dhowells@redhat.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785261982; l=5750;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=YzRfqZvj0aJC/y20MOZHMhGiMroFFO9U4X3LsCu9Yio=;
 b=MxJZ5dJ5dAyqVAzFg+t2YOA2ECQDVce2ugODhhOoVvhtwUmXMI73hQgDvp5VWj1pA8XY3xx0S
 B3Sj9FkExdoDRhMcmGZn5IjfVlJv+2lt62C0SNwJh4wp3YsBgs7vlGF
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

CIFSTCon() bounds its strnlen() over the byte area with the server's
ByteCount minus two, which for ByteCount 0 or 1 goes negative as an int
and converts to a huge size_t.  The later subtraction then wraps __u16
bytes_left, and that is what bounds cifs_strndup_from_utf16().

pByteArea() scales with the response's WordCount, also server-chosen, so
the walk can start past everything the request itself wrote, of which
cifs_buf_get() clears only the first 67 bytes.  KMSAN reports the read of
uninitialised heap, and the bytes reach userspace through
tcon->nativeFileSystem in /proc/fs/cifs/DebugData.

Reject a byte area too small for what the parser consumes.  A response
carrying a service string has at least two bytes there, so nothing valid
is rejected, and both subtractions are then safe.

Fixes: cc20c031bb06 ("cifs: convert CIFSTCon to use new unicode helper functions")
Cc: stable@kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
Found with KMSAN.  KASAN cannot see this one: the read never leaves the allocation.

The server picks both ends of the walk.  pByteArea() is buf + 33 + 2*WordCount + 2 and
CIFSTCon() does not check WordCount, so WordCount 128 puts bcc_ptr at 291 -- past the 67 bytes
cifs_buf_get() clears, past the 256 header_assemble() clears, and past everything the request
itself wrote.  checkSMB() is satisfied, since clc_len = 33 + 2*128 + 2 + 0 = 291 and the
response is exactly 291 bytes.  ByteCount 0 then removes the bound.

Reproducer.  A fake SMB1 server that answers negprot, completes SESSION_SETUP_ANDX, and replies
to TREE_CONNECT_ANDX with WordCount 128 and ByteCount 0.

A/B on v7.2-rc1 with KMSAN, the module rebuilt between arms and the previous session torn down
each time:

  wct 3,   BCC 8, unpatched:   0 reports
  wct 128, BCC 0, patched:     0 reports
  wct 128, BCC 0, unpatched:   110 reports, 28 of them in cifs_utf16_bytes

    BUG: KMSAN: uninit-value in cifs_utf16_bytes+0x37e/0x400 [cifs]
     cifs_utf16_bytes+0x37e/0x400 [cifs]
     cifs_strndup_from_utf16+0x5c/0x210 [cifs]
     CIFSTCon+0x1102/0x1510 [cifs]
     cifs_setup_ipc+0x3b9/0xcf0 [cifs]
     cifs_get_smb_ses+0x16e7/0x2cf0 [cifs]
     cifs_mount_get_session+0x2b2/0x730 [cifs]
     dfs_mount_share+0x43c/0x3510 [cifs]
     cifs_mount+0xcc/0x1140 [cifs]
     __se_sys_fsconfig+0x6e5/0xb10

    Uninit was created at:
     kmem_cache_alloc_noprof+0x556/0xf40
     mempool_alloc_noprof+0x104/0x240
     cifs_buf_get+0x45/0xc0 [cifs]
     CIFSTCon+0x77/0x1510 [cifs]
     cifs_setup_ipc+0x3b9/0xcf0 [cifs]

The uninitialised buffer is allocated by the same CIFSTCon() call that reads it, and the path is
cifs_setup_ipc(), so this fires on the IPC$ tree connect every SMB1 mount performs.  A separate
run caught it through smb2_reconnect_server() as well, i.e. with nobody at the keyboard.

A KMSAN positive control ran first on the same kernel and the same out-of-tree build -- a module
branching on an OPTIMIZER_HIDE_VAR'd uninitialised local -- and reported.  Without that the two
zeros above wouldn't mean anything, since clang folds a plain undef to a defined value.

DebugData is created with proc_create_single("DebugData", 0, ...), and mode 0 is promoted to
S_IRUGO; ls -l confirms -r--r--r--.  open_files, created on the next line, asks for 0400.

690c522fa5a6 ("cifs: use get/put_unaligned functions to access ByteCount") is what made
bytes_left a __u16, so the second subtraction wraps rather than going negative.  The strnlen()
underflow predates it.

I did not add a WordCount check.  checkSMB() rejects a frame shorter than its calculated size,
so once bytes_left is honest the byte area is always inside what was received.

The field this fills is only informational, and failing the whole tree connect over it is a
choice -- but a response with fewer than two bytes of byte area carries no service string, so
there is nothing left to parse.  Happy to make it skip the field and keep the mount if you'd
rather.
---
 fs/smb/client/cifssmb.c | 6 ++++++
 fs/smb/client/trace.h   | 1 +
 2 files changed, 7 insertions(+)

diff --git a/fs/smb/client/cifssmb.c b/fs/smb/client/cifssmb.c
index 40162d5554ea..bb835fdae296 100644
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
index 5b21ad3c15fb..94de11d1c490 100644
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

---
base-commit: 4235cb24ec1e8e96843f3671ba4da2a6ccca2c7b
change-id: 20260728-b4-disp-6b8e68d4-fa25e109c92e

Best regards,
--  
Bryam Vargas <hexlabsecurity@proton.me>

