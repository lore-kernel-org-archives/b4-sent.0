From: Suyuan Wang <shyckless@gmail.com>
Subject: [PATCH v2 0/2] smb: client: don't use SMB2 responses that fail
 signature verification
Date: Mon, 16 Nov 2026 04:06:22 +0000
Message-Id: <20261116-smb2-sign-v2-0-a823a90d0db4@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAD6B+moC/yXM0QpAQBBA0V/RPNuyI0t+RR4Wg1GWdpCSf7d4P
 HW7Fwh5JoEyusDTwcKLC8A4gna0biDFXTBggkZrbZTMDSrhwSlrcp32mS0wKSD0q6eez+9V1b9
 lbyZqt3cA9/0AsUjSwm0AAAA=
X-Change-ID: 20261116-smb2-sign-a6713f5a8208
To: linkinjeon@kernel.org, pc@manguebit.org
Cc: ematsumiya@suse.de, sprasad@microsoft.com, linux-cifs@vger.kernel.org, 
 bharathsm@microsoft.com, ronniesahlberg@gmail.com, 
 samba-technical@lists.samba.org, daniel.birtwhistle@gehealthcare.com, 
 linux-kernel@vger.kernel.org, smfrench@gmail.com, dhowells@redhat.com, 
 tom@talpey.com
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794801982; l=1914;
 i=shyckless@gmail.com; s=default; h=from:subject:message-id;
 bh=jv43A/FOzigTsfPh9FQ0sEdXgmP8WzQQw9ldjxq27kc=;
 b=4EDtA5z7ciZwNK6tzRVSqKlnejoLxWKJVtSj8MvLLr+1y/mYQh/Bdge9RLn/lI6/tqc1ZeiCD
 VeDC8ldJYcwAneMLrwPgvJFFirU9LAkKeqFTVTUzaiu2hb6q5jiG1Pe
X-Developer-Key: i=shyckless@gmail.com; a=ed25519;
 pk=pMtccVGiWES3bV+7YBFuBclkvq2n2HBHQ5azaBrK2lY=
X-Endpoint-Received: by B4 Relay for shyckless@gmail.com/default with auth_id=1498
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

v1 made smb2_check_receive() return the error when a response signature
doesn't verify. Sashiko pointed out that this isn't enough:
compound_send_recv() still passes the response buffer to the caller, and
smb2_compound_op() parses it anyway. It also found that
smb2_readv_callback() can drop the error when the read reaches EOF.

Patch 1 is v1 plus not passing the response on in compound_send_recv().
Patch 2 fixes the read path.

I tested this in QEMU (x86_64, next-20261109, PROVE_LOCKING on) against
Samba 4.15 with "server signing = mandatory", through a proxy that
changes responses without fixing the signature:

- EndOfFile in the QUERY_INFO response of the open/query/close compound
  (stat): with v1 the forged size is copied into the open info, and stat
  only shows the right size because the caller takes -EACCES for
  STATUS_ACCESS_DENIED and opens the file again. With v2 stat fails with
  EACCES.
- READ data, cache=none: without patch 2, cat prints the modified data.
  With it, the read fails with EACCES.
- A file name in QUERY_DIRECTORY (the v1 test): still EACCES, and the
  handle from the CREATE in that compound is closed ("Close unmatched
  open").
- Without the proxy, stat, read, write, ls and rm work as before.

Enzo's point about SMB 3.1.1 tree connect responses is not covered here,
that can be a follow-up.

Changes in v2:
- Patch 1: also don't hand the response to the caller in
  compound_send_recv() (Sashiko)
- Patch 2: new
- v1: https://lore.kernel.org/all/20261113-smb2-sign-v1-1-937ee7c20f08@gmail.com/

---
Suyuan Wang (2):
      smb: client: fail SMB2 responses with a bad signature
      smb: client: don't use read data that failed signature verification

 fs/smb/client/smb2pdu.c       | 2 ++
 fs/smb/client/smb2transport.c | 6 +++++-
 fs/smb/client/transport.c     | 6 ++++++
 3 files changed, 13 insertions(+), 1 deletion(-)

