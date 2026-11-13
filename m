From: Suyuan Wang <shyckless@gmail.com>
Date: Fri, 13 Nov 2026 12:00:43 +0000
Subject: [PATCH] smb: client: fail SMB2 responses with a bad signature
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-smb2-sign-v1-1-937ee7c20f08@gmail.com>
X-B4-Tracking: v=1; b=H4sIAOr79moC/yXM3QpAQBBA4VfRXNsyu+XvVeSCNRhlaQcpeXeLy
 69O5wIhzyRQRhd4Olh4cQEYR2DHxg2kuAsGnegUEY2SudVKeHBK9wZTW6DNMwOhXz31fH6vqv4
 tezuR3d4B3PcDLQXJMW0AAAA=
X-Change-ID: 20261113-smb2-sign-2f316c91c873
To: pc@manguebit.org, linkinjeon@kernel.org
Cc: linux-cifs@vger.kernel.org, sprasad@microsoft.com, ematsumiya@suse.de, 
 smfrench@gmail.com, ronniesahlberg@gmail.com, bharathsm@microsoft.com, 
 linux-kernel@vger.kernel.org, daniel.birtwhistle@gehealthcare.com, 
 samba-technical@lists.samba.org, tom@talpey.com
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794571242; l=3189;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=LRob2AeIi0gkoL5eSGnmBKas0pFGU8uy6TfgbFE1mtQ=;
 b=HU4LLqGOcXfw3OOVZEtRfeFawNQnt3pvzcrPRSZVVEmzXZD7IVGBnvKk7Mf/cF8D6itDlmZxJ
 0j/ps5pnxmcC8GHOzbGfeHx2SNxuIQEKbeQ4VeHeFS1SYyJa14ZuIbT
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
synchronous requests and for smb2_writev_callback(). On a signed but
unencrypted connection, anyone who can modify the traffic can change
e.g. a directory listing, and the client accepts it.

Return the verification error instead.

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
We found this on our own and only saw Daniel's report afterwards.

For SMB1 Steve wanted to keep just logging when the server, but not the
client, required signing:
https://lore.kernel.org/all/CAH2r5msfYRdaGAMuTbni-0T20tQi=N=fT4qxiaQ3siQ_WVm=Qg@mail.gmail.com/
This patch doesn't make that exception. If you want it here too, I can
send a v2 that remembers whether the client required signing.

Tested in QEMU with Samba 4.15 (server signing = mandatory, mounted with
vers=3.1.1,sign) and a proxy in between that renames a file in
QUERY_DIRECTORY responses and leaves the signature as is. Before the
patch the renamed file shows up in getdents64(), after it getdents64()
fails with EACCES. Mount, read and write on the same connection still
work, and lockdep stayed quiet.
---
 fs/smb/client/smb2transport.c | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)

diff --git a/fs/smb/client/smb2transport.c b/fs/smb/client/smb2transport.c
index 080864b24a0c..62121d7a44a8 100644
--- a/fs/smb/client/smb2transport.c
+++ b/fs/smb/client/smb2transport.c
@@ -711,9 +711,11 @@ smb2_check_receive(struct mid_q_entry *mid, struct TCP_Server_Info *server,
 		int rc;
 
 		rc = smb2_verify_signature(&rqst, server);
-		if (rc)
+		if (rc) {
 			cifs_server_dbg(VFS, "SMB signature verification returned error = %d\n",
 				 rc);
+			return rc;
+		}
 	}
 
 	return map_smb2_to_linux_error(mid->resp_buf, log_error);

---
base-commit: 630059a5a632377b9b7b487baccde92b7ae1dd47
change-id: 20261113-smb2-sign-2f316c91c873

Best regards,
--  
Suyuan Wang <shyckless@gmail.com>

