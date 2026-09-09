From: Quanye Yang <quanyeyang@proton.me>
Subject: [PATCH mptcp-next v3 0/2] mptcp: shrink struct
 mptcp_options_received
Date: Wed, 09 Sep 2026 10:40:47 +0800
Message-Id: <20260909-mptcp-shrink-opt-rx-v2-v3-0-92bb3009a665@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/42OwQ6CMBBEf4X07Jp2hQqe/A/jgcIi1dg2bSUYw
 r9b4OLJmOxlsjNvZmKBvKbATtnEPA06aGuSOOwy1vS1uRHoNmmGHCWveA5PFxsHoffaPMC6CH6
 EAaEtiTeyKgRWOUth56nT4wq+sC1jaIzsuv3CS92piQt5cfc6ROvf64pBrJnfhQIEYFsea1UVv
 Oi6s/M2WrN/0tow4B8MXE6k5VKiUqKkDr8x8zx/AMI5g14eAQAA
X-Change-ID: 20260904-mptcp-shrink-opt-rx-v2-d8e0c6951294
To: MPTCP Linux <mptcp@lists.linux.dev>
Cc: Quanye Yang <quanyeyang@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788921669; l=1462;
 i=quanyeyang@proton.me; s=20260801; h=from:subject:message-id;
 bh=u69Q3KBJiQT6+6lKtpAHt4MuYy4KovW6xZ2SKD9e0a8=;
 b=O7/b6aMyNGC+AAaaP3z7HafLooxtlFp412neNlvLMSC8kmS0lnuzxTIilFtM1auaJu4uJnJ4l
 j/Ri/UDawUcC+eR+4b2UQlTbGGg1y4YmfjGil7xriQnj+nztyaqJGvB
X-Developer-Key: i=quanyeyang@proton.me; a=ed25519;
 pk=9L9FrcvzMgxPaBRU6XV0EnqTgjDqVO596rQKSZ9qZoY=
X-Endpoint-Received: by B4 Relay for quanyeyang@proton.me/20260801 with auth_id=963
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

struct mptcp_options_received is the per-packet decode buffer used while
parsing incoming MPTCP options. It is larger than needed because several
suboptions cannot be combined.

This series splits the FASTCLOSE key from rcvr_key, then overlaps the
remaining mutually exclusive payloads in an anonymous union. DSS and
rm_list stay outside the union. On x86_64 the structure shrinks from
136 to 72 bytes.

---
Changes in v3:
- Split the FASTCLOSE key change into its own commit
- Add comments linking union members to their suboptions
- Link to v2: https://patch.msgid.link/20260904-mptcp-shrink-opt-rx-v2-v2-1-d8662bb18ef2@proton.me

Changes in v2:
- Group fields by suboption and move join_id into the MP_JOIN group
- Split rcvr_key into rcvr_key (MP_CAPABLE) and fc_recv_key (MP_FASTCLOSE)
- Overlap MP_JOIN token, thmac and hmac
- Drop the dependency on the invalid-option series
- Link to v1: https://patch.msgid.link/20260904-mptcp-shrink-opt-rx-v1-1-2d87ab9505ff@proton.me

---
Quanye Yang (2):
      mptcp: split FASTCLOSE key from rcvr_key
      mptcp: shrink struct mptcp_options_received

 net/mptcp/options.c  |  6 +++---
 net/mptcp/protocol.h | 44 +++++++++++++++++++++++++++++---------------
 2 files changed, 32 insertions(+), 18 deletions(-)
---
base-commit: d5a4e55ccfb893614646d0f0e5c440daa92b7467
change-id: 20260904-mptcp-shrink-opt-rx-v2-d8e0c6951294

Best regards,
--  
Quanye Yang <quanyeyang@proton.me>

