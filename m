From: Yongjian Wang <echoowall@gmail.com>
Subject: [PATCH net-next v3 0/2] tcp: document and test MTU probing black
 hole fallback
Date: Mon, 23 Nov 2026 19:04:08 +0800
Message-Id: <20261123-tcp-mtu-probing-doc-v1-v3-0-c288c2df9666@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKgdBGsC/4WOwQ6CMBBEf8X07BpaqKAn/8N4oGULNdKSthAM4
 d8t9cLFmMxlMjtvdiEenUZProeFOJy019ZEkx8PRHa1aRF0Ez1hGTtTSksIcoA+jDA4K7RpobE
 SJgo5p1KUvFB1KUgsDw6VnhP4TgwGMDgH8vgmfhRPlGHjbred9sG6d/phoqnxby6KAuesxqxos
 EB1a/tav07S9mlkYntM9RPDIAMsL1yxTFRS4R6zrusHp5POmx8BAAA=
X-Change-ID: 20261117-tcp-mtu-probing-doc-v1-351cb754fa7b
To: corbet@lwn.net, kuba@kernel.org, edumazet@kernel.org, pabeni@redhat.com, 
 davem@davemloft.net, shuah@kernel.org
Cc: Yongjian Wang <echoowall@gmail.com>, ncardwell@google.com, 
 kuniyu@google.com, rdunlap@infradead.org, linux-kselftest@vger.kernel.org, 
 linux-doc@vger.kernel.org, linux-kernel@vger.kernel.org, 
 netdev@vger.kernel.org, skhan@linuxfoundation.org, horms@kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795431849; l=1794;
 i=echoowall@gmail.com; s=20261026; h=from:subject:message-id;
 bh=DDZPPWsZS/fmb7fjrYYLTLl3o/pBegVDzjkgGENcWdQ=;
 b=jsAhLZAF/QnepA5vxEKq3fK4Ci+wO675nO/KwYNKftvHF7zRcBr81kok7uBdxnJqwmUlMPjJQ
 t6elncp7COPC51o1fzrOL6gEwZBS8jK/YK0n0MdhGnfjsFp7PxCMyWN
X-Developer-Key: i=echoowall@gmail.com; a=ed25519;
 pk=9XP6JhqjjPsHCF6UZZZTeqTRnXIa4+ufggnxXtTJ+no=
X-Endpoint-Received: by B4 Relay for echoowall@gmail.com/20261026 with auth_id=1323
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ip-sysctl.rst does not say when TCP detects a black hole with
tcp_mtu_probing=1 or how the MSS drops afterwards. Patch 1 documents
both. Patch 2 adds a packetdrill test for the part that had no
coverage: each further retransmission timeout halves the MSS, down to
tcp_mtu_probe_floor.

On x86_64 KVM, the new test passed in IPv4, IPv6 and IPv4-mapped IPv6.
Variants expecting no floor or no halving failed in all three modes.

Changes in v3:
- Say that only timeouts at which a black hole is still detected lower
  search_low again, and that the floors take precedence over the
  tcp_base_mss cap (patch 1). Kept Eric's and Kuniyuki's tags since
  the change is limited to this sentence.
- Link to v2: https://lore.kernel.org/r/20261118-tcp-mtu-probing-doc-v1-v2-0-e795f20b8cfe@gmail.com

Changes in v2:
- Spell out the 200 ms RTO, say when the time starts and when it is
  checked, and give the resulting detection time (Eric, patch 1).
- Say that the MSS is only lowered, and that each further
  retransmission timeout lowers it again (Eric, patch 1).
- Add a test for tcp_mtu_probe_floor (patch 2).
- Link to v1: https://lore.kernel.org/r/20261117-tcp-mtu-probing-doc-v1-v1-1-552ae04de4ef@gmail.com

Signed-off-by: Yongjian Wang <echoowall@gmail.com>
---
Yongjian Wang (2):
      tcp: document black hole detection for tcp_mtu_probing
      selftests/net: packetdrill: test tcp_mtu_probe_floor

 Documentation/networking/ip-sysctl.rst             | 22 +++++++++++++
 .../tcp_mtu_probing_blackhole_floor.pkt            | 37 ++++++++++++++++++++++
 2 files changed, 59 insertions(+)
---
base-commit: 6ff4c5942a301675eb12e5b49d53a81e604624a1
change-id: 20261117-tcp-mtu-probing-doc-v1-351cb754fa7b

Best regards,
--  
Yongjian Wang <echoowall@gmail.com>

