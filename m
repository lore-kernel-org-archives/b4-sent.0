From: Yongjian Wang <echoowall@gmail.com>
Subject: [PATCH net-next v2 0/2] tcp: document and test MTU probing black
 hole fallback
Date: Wed, 18 Nov 2026 16:10:51 +0800
Message-Id: <20261118-tcp-mtu-probing-doc-v1-v2-0-e795f20b8cfe@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIxd/WoC/4VOSw6CMBC9ipm1Y2ilkrjyHoZFWwYYIy1pC8EQ7
 m7BA5i8zcv7rhApMEW4n1YINHNk7zKR5xPYXruOkJvMQRbyJoSoMNkRhzThGLxh12HjLc4Cr0p
 YU6my1ZWBHB4DtbwcxU9wlNDRkqD+KXEyL7Jp7929Pcfkw+f4MIsj8W8uQ6BSUlNRNlRS++gGz
 e+L9QPU27Z9AUw1Z33YAAAA
X-Change-ID: 20261117-tcp-mtu-probing-doc-v1-351cb754fa7b
To: corbet@lwn.net, edumazet@kernel.org, davem@davemloft.net, 
 kuba@kernel.org, shuah@kernel.org, pabeni@redhat.com
Cc: Yongjian Wang <echoowall@gmail.com>, rdunlap@infradead.org, 
 linux-doc@vger.kernel.org, horms@kernel.org, ncardwell@google.com, 
 kuniyu@google.com, skhan@linuxfoundation.org, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-kselftest@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794989453; l=1424;
 i=echoowall@gmail.com; s=20261026; h=from:subject:message-id;
 bh=R90V3zCpNbOGid8F8EJLRVPdRZBvDvePiD/4QNvUdOg=;
 b=1RQoLj5sSHdElWMgrjWu4kIuFt4WblQTKyPQYOfdgzePK7C9mF9vV1oJIfljMwF6mR2HMo91z
 iS3JD8s57CEB0QIjnCLIq8x3dmcjBEU9kif8JkpXOe64Wotoi57Pi6s
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

 Documentation/networking/ip-sysctl.rst             | 21 ++++++++++++
 .../tcp_mtu_probing_blackhole_floor.pkt            | 37 ++++++++++++++++++++++
 2 files changed, 58 insertions(+)
---
base-commit: 6ff4c5942a301675eb12e5b49d53a81e604624a1
change-id: 20261117-tcp-mtu-probing-doc-v1-351cb754fa7b

Best regards,
--  
Yongjian Wang <echoowall@gmail.com>

