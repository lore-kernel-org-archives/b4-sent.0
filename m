From: Suyuan Wang <shyckless@gmail.com>
Date: Thu, 19 Nov 2026 04:00:48 +0000
Subject: [PATCH v3] smb: client: don't use read data that failed signature
 verification
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261119-smb2-readv-v3-1-f3a8a2eddb1c@gmail.com>
X-B4-Tracking: v=1; b=H4sIAG90/moC/yXMSQqAMAxA0atI1hZsBaeriAtrokZwoNEiiHe36
 vIt/r9AyDEJVNEFjjwLr0tAGkfQje0ykGIMBpOYTGtdKpmtUY5a9CopeouabJojQgg2Rz2f36x
 ufsthJ+r29wD3/QBx6SnEbgAAAA==
X-Change-ID: 20261119-smb2-readv-08fbd1eb37dd
To: linkinjeon@kernel.org, pc@manguebit.org
Cc: bharathsm@microsoft.com, samba-technical@lists.samba.org, 
 dhowells@redhat.com, smfrench@gmail.com, ematsumiya@suse.de, 
 sprasad@microsoft.com, linux-kernel@vger.kernel.org, 
 linux-cifs@vger.kernel.org, tom@talpey.com, ronniesahlberg@gmail.com
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795060847; l=3688;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=URMORExrH4JCtRZ0Ue777N7D5BGWiuT3dVJfKgv73gg=;
 b=ToRXAkguD7E1PnuVkw51/9lK1qF1PYf3Rk+n99xdleliV9SoLKEY7e5xs8imihPGrzEB+6kj+
 aJi1hipwXl7Bd1HzcHJIpO8syyzqTqyfIx1U4Dnb0C+MVq46NX/0ChE
X-Developer-Key: i=shyckless@gmail.com; a=ed25519;
 pk=pMtccVGiWES3bV+7YBFuBclkvq2n2HBHQ5azaBrK2lY=
X-Endpoint-Received: by B4 Relay for shyckless@gmail.com/default with auth_id=1498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Suyuan Wang <stevewong@hust.edu.cn>

When smb2_readv_callback() finds a bad signature, it sets the error in
rdata->result but leaves rdata->got_bytes alone. Further down, a short
read that reaches the remote EOF clears the error again:

    size_t trans = rdata->subreq.transferred + rdata->got_bytes;
    if (trans < rdata->subreq.len &&
        rdata->subreq.start + trans >= netfs_read_remote_i_size(inode)) {
            rdata->result = 0;

and got_bytes is then added to subreq.transferred. So the last part of a
file, or all of a small one, is returned even though its signature is
wrong.

Clearing got_bytes is not enough on its own. If the read starts at or
past the cached remote size, for example because the file has grown on
the server since the size was last fetched, the check above still
matches and the error turns into EOF, or into a zero-filled tail when
NETFS_SREQ_CLEAR_TAIL is set.

Clear got_bytes when the signature check fails, as the retry path in the
same function already does, and only treat a short read as hitting the
remote EOF when the read itself succeeded. That is what commit
1da29f2c39b6 ("netfs, cifs: Fix handling of short DIO read") describes:
"clear the error if a short read occurred without error and the read-to
file position is now at the remote inode size".

Found with a static analysis tool and checked by hand.

Fixes: 1da29f2c39b6 ("netfs, cifs: Fix handling of short DIO read")
Cc: stable@vger.kernel.org
Co-developed-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Suyuan Wang <stevewong@hust.edu.cn>
---
v3:
- Only this patch is resent; 1/2 is in cifs-next.
- Also skip the remote-EOF check when the read has already failed (from
  sashiko's review). Clearing got_bytes alone still let a failed read
  that starts at or past the cached remote size come back as EOF.

Tested in QEMU against cifs-next, signed SMB 3.1.1 to Samba through a
proxy that changes READ data without re-signing it. A cache=none file
is opened (21 bytes), 23 bytes are appended through a second mount, and
the file is read from offset 21:
  v2:  pread returns 0 (EOF), the signature error is lost
  v3:  pread returns -EACCES
Without the proxy both versions read the 23 new bytes, and a read past
the real EOF returns 0.

One side effect: a short read that ends with a retryable error at the
remote EOF is now retried instead of being reported as EOF. I haven't
exercised that path.

v2: https://lore.kernel.org/linux-cifs/20261116-smb2-sign-v2-0-a823a90d0db4@gmail.com/
---
 fs/smb/client/smb2pdu.c | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)

diff --git a/fs/smb/client/smb2pdu.c b/fs/smb/client/smb2pdu.c
index b26bfb4bd91a..f7cb08f5e34f 100644
--- a/fs/smb/client/smb2pdu.c
+++ b/fs/smb/client/smb2pdu.c
@@ -4819,6 +4819,8 @@ smb2_readv_callback(struct TCP_Server_Info *server, struct mid_q_entry *mid)
 					      rc);
 				rdata->subreq.error = rc;
 				rdata->result = rc;
+				/* the data can't be trusted, don't count it */
+				rdata->got_bytes = 0;
 
 				if (is_replayable_error(rc)) {
 					trace_netfs_sreq(&rdata->subreq, netfs_sreq_trace_io_retry_needed);
@@ -4898,7 +4900,7 @@ smb2_readv_callback(struct TCP_Server_Info *server, struct mid_q_entry *mid)
 			__set_bit(NETFS_SREQ_CLEAR_TAIL, &rdata->subreq.flags);
 	} else {
 		size_t trans = rdata->subreq.transferred + rdata->got_bytes;
-		if (trans < rdata->subreq.len &&
+		if (!rdata->result && trans < rdata->subreq.len &&
 		    rdata->subreq.start + trans >= netfs_read_remote_i_size(inode)) {
 			rdata->result = 0;
 			if (rdata->subreq.start + trans >= i_size_read(inode))



