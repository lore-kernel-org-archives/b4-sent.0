From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Subject: [PATCH v4 0/4] net: qrtr: Add support for using identical MHI
 endpoint devices
Date: Thu, 22 Oct 2026 19:43:06 +0200
Message-Id: <20261022-qrtr-multi-ep-v4-0-c6fdb75fcd3e@oss.qualcomm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIACpL2moC/3XNTQ6CMBAF4KuYri1pp/wUV97DuCjtqDVAoQWiI
 dzdghtjdDPJS958byYBvcVADruZeJxssK6NId3viL6p9orUmpgJMMhZySXt/eBpM9aDpdhRDYW
 GSmcpIifxp/N4sY/NO53fOYzVHfWwImvjZsPg/HMbnPja+2dPnDIqFcu1UiKXRhxdCEk/qlq7p
 kniIevEBB8I8G8EIgKFMZIZmXLF/iDiE4FvREREMyYFRynLrPiBLMvyAojzXoJNAQAA
X-Change-ID: 20260918-qrtr-multi-ep-c27c2bc54ee1
To: Manivannan Sadhasivam <mani@kernel.org>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>, Jeff Johnson <jjohnson@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-wireless@vger.kernel.org, 
 ath11k@lists.infradead.org, ath12k@lists.infradead.org, 
 Bjorn Andersson <andersson@kernel.org>, 
 Chris Lew <christopher.lew@oss.qualcomm.com>, 
 Deepak Kumar Singh <deepak.singh@oss.qualcomm.com>, 
 Raj Kumar Bhagat <raj.bhagat@oss.qualcomm.com>, 
 Juha-Matti Tilli <juha-matti.tilli@iki.fi>, 
 Jeff Hugo <jeff.hugo@oss.qualcomm.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3962;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=q+w1LBsK2b8ldE4G3w95CnlIooEs/ixDTJAOtFqRgYI=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBq2kszz4zwVzJKE+K4NeeIkUmI4zQIjghu5A/p/
 fK7iEXr3TaJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCatpLMwAKCRBVnxHm/pHO
 9YVhB/9PbMqL00DWGsIB4zThW8y+Md9kmNepLqE6qV36OtjjBZfZrWyrYurgELw5kPGfhO8DTng
 TpHi7lZ3arKGzauH0lIQWHp8DrtqTCt6GMrIJrJvMHvZl4NaoIBIo4gD/Nw17jxI4FQQR5U2YM2
 X3K9UR1b6y3/okrgEdK3oM91rzLD3P/oFw9C71g+wbejaHv8iy8Th1J2IUCP0nL2IgoTgeni6CZ
 4Nx+FYeUCbeayl1/lesuNfoahEzd0ZCazuIXC6lOKYnEEi3ALYL4yviAVi02x41RrZjx1Ue2gFV
 UC5rMWUW8ZeScArSX955IYpNMzS+g+FQF+vch6Xb9d+ShIFA
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

This series reworks the QRTR driver to add support for using identical MHI
endpoint devices at the same time. Currently, QRTR driver has a limitation on
using more than one identical MHI endpoint devices like QCS6490 or any Qcom
Endpoint device making use of QRTR at the same time. Because of the fact that
these devices will have the identical QRTR node id, they cannot be used at the
same time, on the same host machine.

This limitation is a blocker for running upstream kernel on devices like Qcom
based routers as they often have multiple identical WLAN Endpoint devices
connected to the Router SoC.

This series supersedes the following 2 series from Juha:
https://lore.kernel.org/all/20260915054207.2513877-1-juha-matti.tilli@iki.fi
https://lore.kernel.org/all/20260915074135.2567411-1-juha-matti.tilli@iki.fi

Compared to the series from Juha, this series simplifies the multi-endpoint
support by computing a unique node id for each MHI endpoint and uses it for the
internal QRTR book keeping. This ensures that even if the MHI endpoint devices
have same node ids, the host QRTR will always use a unique node id for each one
of them.

More details can be found in the individual patches.

Merge Strategy
==============

Since both QRTR and ath drivers are falling under the networking tree, the whole
series can be merged through netdev tree.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
Changes in v4:
- Moved the 'ep_nid' and the node id assignment into a single
  'qrtr_nodes_lock' critical section and used READ_ONCE() elsewhere
- Propagated the radix tree insert error out of qrtr_node_assign() and
  rejected the packet or failed the endpoint registration
- Fixed the assign condition that stopped adding bridged node ids as
  lookup keys
- Moved the control packet length check to qrtr_endpoint_post() and
  extended it to DEL_SERVER and DEL_CLIENT
- Rejected endpoint node ids at and above QRTR_NODE_HOST_BASE
- Returned error for the QMI message received from an unknown server in
  ath{11k,12k} so that the QMI core drops the service
- Dropped Juha's Tested-by and Vasanth's Reviewed-bt as the code changed since v3
- Link to v3: https://patch.msgid.link/20260922-qrtr-multi-ep-v3-0-c00831e88957@oss.qualcomm.com

Changes in v3:
- Added missing qrtr_node_rewrite_ctrl() for QRTR_TYPE_RESUME_TX
- Fixed the types of ath{11k/12k}_pci_get_qrtr_node_id() and helpers to use
  'unsigned int' to match qrtr_host_node_id()
- Collected tags
- Link to v2: https://patch.msgid.link/20260921-qrtr-multi-ep-v2-0-27dd80d841a0@oss.qualcomm.com

Changes in v2:
- Rebased on top of net-next/main
- Used READ/WRITE_ONCE for reading/writing ep_nid
- Link to v1: https://patch.msgid.link/20260918-qrtr-multi-ep-v1-0-8a06caa368d3@oss.qualcomm.com

---
Manivannan Sadhasivam (4):
      net: qrtr: Allow the host QRTR to assign a unique node id
      net: qrtr: Assign unique node id for MHI endpoints
      wifi: ath11k: Connect to the QMI server belonging to the device owned by this driver
      wifi: ath12k: Connect to the QMI server belonging to the device owned by this driver

 MAINTAINERS                           |   1 +
 drivers/net/wireless/ath/ath11k/hif.h |   9 +++
 drivers/net/wireless/ath/ath11k/pci.c |   9 +++
 drivers/net/wireless/ath/ath11k/qmi.c |  10 +++
 drivers/net/wireless/ath/ath12k/hif.h |   9 +++
 drivers/net/wireless/ath/ath12k/pci.c |   9 +++
 drivers/net/wireless/ath/ath12k/qmi.c |  11 +++
 include/net/qrtr.h                    |  22 ++++++
 net/qrtr/af_qrtr.c                    | 141 ++++++++++++++++++++++++++++++----
 net/qrtr/mhi.c                        |   4 +-
 10 files changed, 208 insertions(+), 17 deletions(-)
---
base-commit: 8830e65ed46de41f849eefb8ba227d4852c460f6
change-id: 20260918-qrtr-multi-ep-c27c2bc54ee1

Best regards,
--  
மணிவண்ணன் சதாசிவம்

