From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Tue, 28 Jul 2026 13:06:13 -0500
Subject: [PATCH] smb: client: restore the data_offset bound in
 is_valid_oplock_break()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260728-b4-disp-22baa716-v1-1-f8325242fd13@proton.me>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMPQ6DMAxA4asgz7VEzE8QV6kYkmDAHQDFLUJC3
 J0Uxm947wDlKKzQZgdE3kRlmRPMK4MwuXlklD4ZKKc6t9SgL7EXXZHIO2dNjWXR2DCwqQJ5SNk
 aeZD9Xr67x/rzHw7f/wfO8wIOJ/+XdAAAAA==
X-Change-ID: 20260728-b4-disp-22baa716-4387cfe15c2b
To: Paulo Alcantara <pc@manguebit.org>, Steve French <sfrench@samba.org>
Cc: linux-kernel@vger.kernel.org, Shyam Prasad N <sprasad@microsoft.com>, 
 David Howells <dhowells@redhat.com>, samba-technical@lists.samba.org, 
 Bharath SM <bharathsm@microsoft.com>, 
 Ronnie Sahlberg <ronniesahlberg@gmail.com>, linux-cifs@vger.kernel.org, 
 Tom Talpey <tom@talpey.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785261972; l=4574;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=CwavSO6EzyARnEOHNjE20Bb+u4be0TN+OVMqBdkQGsc=;
 b=xU+aGUby8fS15RDEnecOl/KaxHKdyLecAuGmbaAFcsZvsI48ZwPn23Yf3o7NQUS8x+qL0cIDG
 +NnSjhfW/5BBMs7Lub5CoCHU5dA21NredMN5Rop9kX96iYDmo+e/w0o
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit 83bfbd0bb902 ("cifs: Remove the RFC1002 header from smb_hdr")
changed the quantity this bound is measured against.  It used to be
srv->total_read minus the 4-byte RFC1002 preamble that total_read then
included, so it was the SMB message length.  The same commit stopped
counting the preamble, and the mechanical substitution to
srv->total_read - srv->pdu_size left an expression that is identically
zero: standard_receive3() reads MID_HEADER_SIZE() bytes and then exactly
pdu_length - MID_HEADER_SIZE() more, adding both to total_read.

len is therefore 0, the subtraction below it wraps, and no __u32
DataOffset can exceed the result, so the check from commit 097f5863b1a0
("cifs: read overflow in is_valid_oplock_break()") no longer rejects
anything.  Use total_read, which is now the message length on its own.

Fixes: 83bfbd0bb902 ("cifs: Remove the RFC1002 header from smb_hdr")
Cc: stable@kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
The two derefs only run when cifs_dbg(FYI, ...) evaluates its arguments, that is with cifsFYI
set and the pr_debug callsite live.  Without either, pr_debug_ratelimited() is no_printk() and
nothing is touched, which is why I'm sending this as a hardening fix rather than a security
report.  It is not hypothetical either: usage.rst tells people to
`echo 7 > /proc/fs/cifs/cifsFYI` when troubleshooting, and distro kernels build with
CONFIG_DYNAMIC_DEBUG=y.

Reproducer.  A fake SMB1 server that answers negprot and then pushes one unsolicited
SMB_COM_NT_TRANSACT response carrying SMBFLG_RESPONSE, BCC 16 and a chosen DataOffset.  A frame
matching no pending mid falls through to ->is_oplock_break() in cifs_demultiplex_thread(), so
neither a session nor a tree connect is needed, and the read happens in the cifsd thread.

A/B on v7.2-rc1 with KASAN, cifs built with -DDEBUG so pr_debug evaluates its arguments, all
three arms in one boot with kasan.fault=report:

  DataOffset 40, unpatched:    "dnotify on  Action: 0x0" -- both derefs run, clean
  DataOffset 512, patched:     "Invalid data_offset 512" -- rejected before the deref, clean
  DataOffset 512, unpatched:

    BUG: KASAN: slab-use-after-free in is_valid_oplock_break.cold+0x177/0x20f [cifs]
    Read of size 4 at addr ffff888119929604 by task cifsd/2308
     is_valid_oplock_break.cold+0x177/0x20f [cifs]
     cifs_demultiplex_thread+0xb2a/0x2320 [cifs]
    The buggy address belongs to the object at ffff888119929600
     which belongs to the cache cifs_small_rq of size 448
    The buggy address is located 4 bytes inside of
     freed 448-byte region [ffff888119929600, ffff8881199297c0)
    Freed by task 2307:
     cifs_small_buf_release+0x3b/0xd0 [cifs]
     SendReceive+0x1e8/0x6b0 [cifs]
     CIFSSMBNegotiate+0x3a0/0x1750 [cifs]

512 past a 448-byte cifs_small_rq object lands in the next slot, which at that moment held the
negprot buffer freed a few lines earlier -- hence use-after-free rather than out-of-bounds.
The primitive is the displacement; what it lands on is whatever the pool happens to hold.

83bfbd0bb902 first appeared in v6.19-rc1.

What this does not close: the bound covers the fixed part of the record, but the FileName the
next line prints with %s is a flex array, FileNameLength is never read, and nothing guarantees a
NUL, so that walk can still leave the frame.  It has been that way since the code was imported,
so it is not part of this regression, and I haven't reproduced it, so folding an unmeasured
change into a fix headed for stable would be the wrong call.  Happy to make it a two-patch
series if you'd prefer them together.
---
 fs/smb/client/smb1misc.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/fs/smb/client/smb1misc.c b/fs/smb/client/smb1misc.c
index ba56023010d8..cdfbbff24b72 100644
--- a/fs/smb/client/smb1misc.c
+++ b/fs/smb/client/smb1misc.c
@@ -80,7 +80,8 @@ is_valid_oplock_break(char *buffer, struct TCP_Server_Info *srv)
 			(struct smb_com_transaction_change_notify_rsp *)buf;
 		struct file_notify_information *pnotify;
 		__u32 data_offset = 0;
-		size_t len = srv->total_read - srv->pdu_size;
+		/* total_read excludes the RFC1002 preamble */
+		size_t len = srv->total_read;
 
 		if (get_bcc(buf) > sizeof(struct file_notify_information)) {
 			data_offset = le32_to_cpu(pSMBr->DataOffset);

---
base-commit: 4235cb24ec1e8e96843f3671ba4da2a6ccca2c7b
change-id: 20260728-b4-disp-22baa716-4387cfe15c2b

Best regards,
--  
Bryam Vargas <hexlabsecurity@proton.me>

