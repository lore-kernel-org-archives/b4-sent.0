From: Suyuan Wang <shyckless@gmail.com>
Date: Mon, 16 Nov 2026 04:06:24 +0000
Subject: [PATCH v2 2/2] smb: client: don't use read data that failed
 signature verification
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261116-smb2-sign-v2-2-a823a90d0db4@gmail.com>
References: <20261116-smb2-sign-v2-0-a823a90d0db4@gmail.com>
In-Reply-To: <20261116-smb2-sign-v2-0-a823a90d0db4@gmail.com>
To: linkinjeon@kernel.org, pc@manguebit.org
Cc: ematsumiya@suse.de, sprasad@microsoft.com, linux-cifs@vger.kernel.org, 
 bharathsm@microsoft.com, ronniesahlberg@gmail.com, 
 samba-technical@lists.samba.org, daniel.birtwhistle@gehealthcare.com, 
 linux-kernel@vger.kernel.org, smfrench@gmail.com, dhowells@redhat.com, 
 tom@talpey.com
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794801982; l=1617;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=3pzHhLlm0VqsPqETYBr3UUbM6tyVccoN6rYtsY79lWg=;
 b=kg87p8B0s9W/1FD9ZZXQa62y0j/jVxUBkqXQ5+WZF38sbgreIiaL9vp5wlgcWRaqoIafSg/fQ
 GjW8gMy8jFPBRDcFFJgdy2x/mLiZUhADpZQxZQG3LtY5imST+cU8TiH
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

Clear got_bytes when the signature check fails, as the retry path in the
same function already does.

Found with a static analysis tool and checked by hand.

Fixes: 1da29f2c39b6 ("netfs, cifs: Fix handling of short DIO read")
Cc: stable@vger.kernel.org
Co-developed-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Suyuan Wang <stevewong@hust.edu.cn>
---
 fs/smb/client/smb2pdu.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/fs/smb/client/smb2pdu.c b/fs/smb/client/smb2pdu.c
index f85595136ef8..1245572c022e 100644
--- a/fs/smb/client/smb2pdu.c
+++ b/fs/smb/client/smb2pdu.c
@@ -4723,6 +4723,8 @@ smb2_readv_callback(struct TCP_Server_Info *server, struct mid_q_entry *mid)
 					      rc);
 				rdata->subreq.error = rc;
 				rdata->result = rc;
+				/* the data can't be trusted, don't count it */
+				rdata->got_bytes = 0;
 
 				if (is_replayable_error(rc)) {
 					trace_netfs_sreq(&rdata->subreq, netfs_sreq_trace_io_retry_needed);

-- 
2.34.1

