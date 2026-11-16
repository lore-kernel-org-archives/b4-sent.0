From: Suyuan Wang <shyckless@gmail.com>
Date: Mon, 16 Nov 2026 04:06:23 +0000
Subject: [PATCH v2 1/2] smb: client: fail SMB2 responses with a bad
 signature
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261116-smb2-sign-v2-1-a823a90d0db4@gmail.com>
References: <20261116-smb2-sign-v2-0-a823a90d0db4@gmail.com>
In-Reply-To: <20261116-smb2-sign-v2-0-a823a90d0db4@gmail.com>
To: linkinjeon@kernel.org, pc@manguebit.org
Cc: ematsumiya@suse.de, sprasad@microsoft.com, linux-cifs@vger.kernel.org, 
 bharathsm@microsoft.com, ronniesahlberg@gmail.com, 
 samba-technical@lists.samba.org, daniel.birtwhistle@gehealthcare.com, 
 linux-kernel@vger.kernel.org, smfrench@gmail.com, dhowells@redhat.com, 
 tom@talpey.com
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794801982; l=3644;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=GRCAyhw8W4Nd3CFnmrKZixyJSJ4lqFc04PFF7+v+L/I=;
 b=MmJB7lHaglzwEjt9lIs/pV7Bud2fJyqwEim3ZJ0TWgrDiXI2Ly9exeTqFAu/svt32Td9mENzz
 nhsNQguQY/ECgvt1qXcauyCaIHcwZjmPnCfl2SiOH+YOS5juziyqM/6
X-Developer-Key: i=shyckless@gmail.com; a=ed25519;
 pk=pMtccVGiWES3bV+7YBFuBclkvq2n2HBHQ5azaBrK2lY=
X-Endpoint-Received: by B4 Relay for shyckless@gmail.com/default with auth_id=1498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Suyuan Wang <stevewong@hust.edu.cn>

smb2_check_receive() checks the response signature when signing is on,
but a failed check is only logged:

    rc = smb2_verify_signature(&rqst, server);
    if (rc)
            cifs_server_dbg(VFS, "SMB signature verification returned ...",
                            rc);
    ...
    return map_smb2_to_linux_error(mid->resp_buf, log_error);

The status from the response is returned as usual, and the caller goes
on to use a response whose signature is wrong. This is the path for
synchronous and compound requests and for smb2_writev_callback(). On a
signed but unencrypted connection, anyone who can modify the traffic
can change e.g. a directory listing or file attributes, and the client
accepts it.

Return the verification error instead. That alone is not enough for
compound_send_recv(), which still hands the response buffer to the
caller after check_receive() fails. smb2_compound_op() then maps the
status from that buffer again and copies the payload out, and other
callers look at the buffer on error too, e.g. smb2_open_file() parses
a symlink target out of a STATUS_STOPPED_ON_SYMLINK response. So also
mark the mid MID_RESPONSE_MALFORMED, and have compound_send_recv() handle
it like a mid in a bad state: mark the earlier mids cancelled, so that a
CREATE which did succeed gets its handle closed, and don't pass any
response on.

Unlike the SMB1 fix in commit dc96f01d54cc ("smb: client: terminate
session upon failed client required signing"), don't reconnect: this
runs in the thread that sent the request, and only cifsd should call
cifs_reconnect(). And fail the request whichever side required signing,
since a response with a bad signature can't be trusted either way.

Found with a static analysis tool and checked by hand.

Reported-by: Daniel Birtwhistle <daniel.birtwhistle@gehealthcare.com>
Closes: https://lore.kernel.org/linux-cifs/SN4PR22MB28883DAF57E0B4D4BFB1C22AEEC42@SN4PR22MB2888.namprd22.prod.outlook.com/
Fixes: 3c1bf7e48e9e ("CIFS: Enable signing in SMB2")
Cc: stable@vger.kernel.org
Co-developed-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Kaixuan Li <kaixuan.li@ntu.edu.sg>
Signed-off-by: Suyuan Wang <stevewong@hust.edu.cn>
---
 fs/smb/client/smb2transport.c | 6 +++++-
 fs/smb/client/transport.c     | 6 ++++++
 2 files changed, 11 insertions(+), 1 deletion(-)

diff --git a/fs/smb/client/smb2transport.c b/fs/smb/client/smb2transport.c
index 080864b24a0c..5d6871553ee9 100644
--- a/fs/smb/client/smb2transport.c
+++ b/fs/smb/client/smb2transport.c
@@ -711,9 +711,13 @@ smb2_check_receive(struct mid_q_entry *mid, struct TCP_Server_Info *server,
 		int rc;
 
 		rc = smb2_verify_signature(&rqst, server);
-		if (rc)
+		if (rc) {
 			cifs_server_dbg(VFS, "SMB signature verification returned error = %d\n",
 				 rc);
+			/* compound_send_recv() must not pass this response on */
+			mid->mid_state = MID_RESPONSE_MALFORMED;
+			return rc;
+		}
 	}
 
 	return map_smb2_to_linux_error(mid->resp_buf, log_error);
diff --git a/fs/smb/client/transport.c b/fs/smb/client/transport.c
index d0d0159c1061..f1ba9701b545 100644
--- a/fs/smb/client/transport.c
+++ b/fs/smb/client/transport.c
@@ -1110,6 +1110,12 @@ compound_send_recv(const unsigned int xid, struct cifs_ses *ses,
 
 		rc = server->ops->check_receive(mid[i], server,
 						flags & CIFS_LOG_ERROR);
+		if (mid[i]->mid_state != MID_RESPONSE_READY) {
+			/* Bad signature, don't let the caller parse any response */
+			cifs_mark_compound_mids_cancelled(mid, i);
+			num_processed = 0;
+			goto out;
+		}
 		num_processed = i + 1;
 	}
 

-- 
2.34.1

