From: Nelson Escobar <neescoba@cisco.com>
Subject: [PATCH net-next v2 0/5] enic: Use all the resources configured on
 VIC
Date: Thu, 24 Oct 2024 18:19:42 -0700
Message-Id: <20241024-remove_vic_resource_limits-v2-0-039b8cae5fdd@cisco.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAC7yGmcC/y2NwQrCMBBEf0X2bEq6xhY9+R9SShq3dsEmko2hU
 vrvhuJpGB7zZgWhyCRwPawQKbNw8KXg8QBusv5Jih+lA2o0tcaTijSHTH1m10eS8ImO+hfPnES
 RtY0ZL9ScxwGK4B1p5GWX38FTUp6WBF0hE0sK8bu/5nrn/wPUpm51W2FrNCosExIXBntzXLJyY
 YZu27YfBfx0wbgAAAA=
X-Change-ID: 20241023-remove_vic_resource_limits-eaa64f9e65fb
To: John Daley <johndale@cisco.com>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Christian Benvenuti <benve@cisco.com>, Satish Kharat <satishkh@cisco.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Nelson Escobar <neescoba@cisco.com>, Simon Horman <horms@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1729819262; l=1555;
 i=neescoba@cisco.com; s=20241023; h=from:subject:message-id;
 bh=1otnsKA6AXNJNQvjX5o3McHr/yUE64d7zrdHdVp9Ttk=;
 b=rxT7brw5elvfAKfY0od+z1O8R1B5DOpECJDXa8DVkzNHCyto+LC4iXbSrZ7Q/Z+Cv6dkmCldO
 0rW82RCUmlsD9xDTJ1D4xcs6nx0mqkuFsUj2t0HdCzsdtp0MGBi0VeO
X-Developer-Key: i=neescoba@cisco.com; a=ed25519;
 pk=bLqWB7VU0KFoVybF4LVB4c2Redvnplt7+5zLHf4KwZM=
X-Endpoint-Received: by B4 Relay for neescoba@cisco.com/20241023 with auth_id=255
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Allow users to configure and use more than 8 rx queues and 8 tx queues
on the Cisco VIC.

This series changes the maximum number of tx and rx queues supported
from 8 to the hardware limit of 256, and allocates memory based on the
number of resources configured on the VIC.

Signed-off-by: Nelson Escobar <neescoba@cisco.com>
---
Changes in v2:
- Followed Kalesh's suggestions: removed redundant NULL assigments,
  returning -ENOMEM directly
- Reviewed-by tag for Simon Horman <horms@kernel.org>
- Marked Satish Kharat and John Daley as co-developers to better reflect
  their role in this patch set
- Link to v1: https://lore.kernel.org/r/20241022041707.27402-2-neescoba@cisco.com

---
Nelson Escobar (5):
      enic: Create enic_wq/rq structures to bundle per wq/rq data
      enic: Make MSI-X I/O interrupts come after the other required ones
      enic: Save resource counts we read from HW
      enic: Allocate arrays in enic struct based on VIC config
      enic: Adjust used MSI-X wq/rq/cq/interrupt resources in a more robust way

 drivers/net/ethernet/cisco/enic/enic.h         |  62 ++--
 drivers/net/ethernet/cisco/enic/enic_ethtool.c |   8 +-
 drivers/net/ethernet/cisco/enic/enic_main.c    | 397 +++++++++++++++----------
 drivers/net/ethernet/cisco/enic/enic_res.c     |  33 +-
 4 files changed, 294 insertions(+), 206 deletions(-)
---
base-commit: 6f07cd8301706b661776074ddc97c991d107cc91
change-id: 20241023-remove_vic_resource_limits-eaa64f9e65fb

Best regards,
-- 
Nelson Escobar <neescoba@cisco.com>

