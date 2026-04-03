From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Subject: [PATCH v2 0/5] net: qrtr: ns: A bunch of fixs
Date: Fri, 03 Apr 2026 21:36:03 +0530
Message-Id: <20260403-qrtr-fix-v2-0-f88a14859c63@oss.qualcomm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAGvlz2kC/02MQQ6CMBBFr0Jm7RA6UIKuvIdxQXEKFS06LcaEc
 HeLbly+n/ffAoHFcYBDtoDwywU3+QS0y6AbWt8zuktioILqoiwVPiUKWvdGowvqqGZtqxqS/hB
 O8zd1Ov84zObKXdz+m2FlumMchNu/JO0pdXWVU6M0NRUqHGfTHkcWz7d8kh7W9QNUDa5ipwAAA
 A==
X-Change-ID: 20260331-qrtr-fix-b502c26e5f46
To: Manivannan Sadhasivam <mani@kernel.org>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Yiming Qian <yimingqian591@gmail.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.15.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1032;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=vYHiRwhsDAzLREfvrBGT0BNZkK9bUpTZpszFUTATl3Q=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBpz+VzOfxpKLoJEkpNrmUhIgZ6WHuk8IT6hFx/d
 2hFZmeo9cKJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCac/lcwAKCRBVnxHm/pHO
 9b2oB/9RkPyY+LUXDdx9G/ddlzlq37DdOq9PsAO2f6xg+x5bop/uatsBxpbjVqzyG2BznrMk5sA
 CmEmgrL7EeDbPCqg2ZdOf3lq+6BpmuZSxKfhTtjPZRu0/YaMgkPnfNRNAs2UUwi0+w+ZgDqkG7R
 l/viU1X+06/9+1TfPRplcT970mQ1OrICMnLL9BLzv9gKnNfsOrdksDHjSKE7DLrPW3HbziA3QRI
 OKwqfke3ev8DUBlXy5q4rHX7ren0TW0upeklKbEsyqGLDTsM4QKDQbChxyvQG/0BQjHtxbedB/b
 ngoOMt4NQ9O/dJ3FVL58NJs7NxXAokTLULep0lwnUKZAPe4l
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

This series fixes a bunch of possible memory exhaustion issues in the QRTR
nameserver.

Manivannan Sadhasivam (2):
  net: qrtr: ns: Limit the maximum server registration per node
  net: qrtr: ns: Limit the maximum lookups per socket

 net/qrtr/ns.c | 38 ++++++++++++++++++++++++++++++++++----
 1 file changed, 34 insertions(+), 4 deletions(-)

--
2.51.0

---
Manivannan Sadhasivam (5):
      net: qrtr: ns: Limit the maximum server registration per node
      net: qrtr: ns: Limit the maximum number of lookups
      net: qrtr: ns: Free the node during ctrl_cmd_bye()
      net: qrtr: ns: Limit the total number of nodes
      net: qrtr: ns: Fix use-after-free in driver remove()

 net/qrtr/ns.c | 71 ++++++++++++++++++++++++++++++++++++++++++++++++++---------
 1 file changed, 61 insertions(+), 10 deletions(-)
---
base-commit: 6de23f81a5e08be8fbf5e8d7e9febc72a5b5f27f
change-id: 20260331-qrtr-fix-b502c26e5f46

Best regards,
--  
Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>

