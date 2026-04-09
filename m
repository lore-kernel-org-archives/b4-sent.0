From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Subject: [PATCH v3 0/5] net: qrtr: ns: A bunch of fixs
Date: Thu, 09 Apr 2026 23:04:11 +0530
Message-Id: <20260409-qrtr-fix-v3-0-00a8a5ff2b51@oss.qualcomm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABPj12kC/02OSw6CMBCGr2K6dkiZtqS68h7GRamDVIXqFIjGc
 HeLLnQzyTf5Xy+RiAMlsV29BNMUUoh9BrVeCd+6/kQQjpkFSqykUiXceWBowgNqI9FjRabRlcj
 yG1N+f6L2hy+nsT6THxb/omg4djC0TO4vEjeYc40u0JYGrYYSLmPtdhfinq5F5NNibUMaIj8/M
 ydcKr52LdVv0YQgobHWldqaja/ULqZU3Ed39bHrinzEYZ7nNxs5c970AAAA
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=949;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=Gj136g/kwa38w+/k4mfmIaV2zPHIHZSBmkO4GwE8mh0=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBp1+MUJAogw19JAzFEh47vDzrMQ1OW1lrxzap1O
 SpdPxnd5bKJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCadfjFAAKCRBVnxHm/pHO
 9bAMB/9lerWH44bHX4s2xq30YdjVETr4NMjyYm+h7jlQDLvEUlhGRvDlkkAo/MesNCdkAHmS6n8
 kmnCD+AgovjwjpP9rN23JQ7VH4/qCX/togkVa1lXKFe6Kr5L4zJrn63ns8EaniqsaLUO+pTliI3
 SlhJ+y6+MXOoJfA0zYWf5xBw6FSvAeKic5luupbgYaXdiqJknM40BzmufTzyeaiXuRHVjRB6HQK
 BWW+1wZh8oUFmMZc0fpAtBmmEgGYlC+PWBYZzOSjyK16fNSEm5rguhmwz+yvzaVAe1tKpw0TG2o
 q5Xxpsq0jBj409/ihH6rDYvypeTVF7heOnJL6ao8tODvKMfP
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

This series fixes a bunch of possible memory exhaustion issues in the QRTR
nameserver.

---
Changes in v3:
- Fixed the issues in remove() callback and other places reported by Sashiko
- Link to v2: https://patch.msgid.link/20260403-qrtr-fix-v2-0-f88a14859c63@oss.qualcomm.com

---
Manivannan Sadhasivam (5):
      net: qrtr: ns: Limit the maximum server registration per node
      net: qrtr: ns: Limit the maximum number of lookups
      net: qrtr: ns: Free the node during ctrl_cmd_bye()
      net: qrtr: ns: Limit the total number of nodes
      net: qrtr: ns: Fix use-after-free in driver remove()

 net/qrtr/ns.c | 79 +++++++++++++++++++++++++++++++++++++++++++++++++++--------
 1 file changed, 69 insertions(+), 10 deletions(-)
---
base-commit: 6de23f81a5e08be8fbf5e8d7e9febc72a5b5f27f
change-id: 20260331-qrtr-fix-b502c26e5f46

Best regards,
--  
Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>

