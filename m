From: Ekansh Gupta <ekansh.gupta@oss.qualcomm.com>
Subject: [PATCH 0/3] Introduce generic context device bus for IOMMU context
 isolation
Date: Tue, 14 Apr 2026 22:01:14 +0530
Message-Id: <20260414-computebus-v1-0-4d904d40926a@oss.qualcomm.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIANJr3mkC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDE0MT3eT83ILSktSk0mLdVAtTozRLS5PUVCNTJaCGgqLUtMwKsGHRsbW
 1AE2VhC1cAAAA
X-Change-ID: 20260414-computebus-e852f994ee25
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Danilo Krummrich <dakr@kernel.org>, 
 Thierry Reding <thierry.reding@kernel.org>, 
 Mikko Perttunen <mperttunen@nvidia.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, Joerg Roedel <joro@8bytes.org>, 
 Will Deacon <will@kernel.org>, Robin Murphy <robin.murphy@arm.com>, 
 Arnd Bergmann <arnd@arndb.de>, Srinivas Kandagatla <srini@kernel.org>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 Bharath Kumar <quic_bkumar@quicinc.com>, 
 Chenna Kesava Raju <quic_chennak@quicinc.com>
Cc: linux-kernel@vger.kernel.org, driver-core@lists.linux.dev, 
 dri-devel@lists.freedesktop.org, linux-tegra@vger.kernel.org, 
 iommu@lists.linux.dev, linux-arm-msm@vger.kernel.org, 
 Ekansh Gupta <ekansh.gupta@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1776184278; l=2594;
 i=ekansh.gupta@oss.qualcomm.com; s=20260223; h=from:subject:message-id;
 bh=gNqdE9d81DRyUjeuqyd3JZqlKkL8O3oEZBn4pvoKquI=;
 b=baxjKIj5uScDYrCIYv1qYvM3a63CPT0wbgKn65lPfsAUxTA/AlgOpd2u7suXXwN600FcGRQqF
 3nuqpzm5lmqBrQTEYy04WW8GTzfnkrDDDEQwfOQK54jlvxWaVJzVsAz
X-Developer-Key: i=ekansh.gupta@oss.qualcomm.com; a=ed25519;
 pk=n0SepARizye+pYjhjg1RA5J+Nq4+IJbyRcBybU+/ERQ=
X-Endpoint-Received: by B4 Relay for ekansh.gupta@oss.qualcomm.com/20260223 with auth_id=647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series introduces a generic context device bus to replace driver-specific
implementations and enable proper IOMMU handling of synthetic context bank
devices used by accelerator and GPU drivers.

Background:
-----------
During review of the fastrpc driver changes [1], it was pointed out that using
a platform driver for compute bank (CB) devices was incorrect since these are
synthetic IOMMU context banks, not real platform devices. The platform driver
approach also had a race condition where device nodes were created before
channel resources were initialized, and probe was async, allowing applications
to open devices before sessions were available.

The reviewer suggested following the pattern used in host1x_memory_context_list_init()
and creating devices manually. During review of the QDA driver [2], it was
further suggested to create a generic bus type that could be shared across
multiple drivers rather than having each driver implement its own bus.

This series implements that suggestion by:
1. Creating a generic context_device_bus_type in drivers/base/
2. Migrating the existing host1x driver to use it
3. Converting fastrpc to use it, fixing the race condition in the process

References:
-----------
[1] Fastrpc platform driver review:
    https://lore.kernel.org/all/golcrcr6voafr3fqsnihyjyut36sii55vzws4josfhkjjg3nie@ur43qq2kvlsv/

[2] QDA driver review requesting generic bus:
    https://lore.kernel.org/all/en5tdgemre7vq5qihe6wnkbrro24vtzwfxwqrpnrrmugxoszs7@x2ox64zeznvd/

Signed-off-by: Ekansh Gupta <ekansh.gupta@oss.qualcomm.com>
---
Ekansh Gupta (3):
      drivers: base: Add generic context device bus
      gpu: host1x: Migrate to generic context device bus
      misc: fastrpc: Use context device bus for compute banks

 drivers/base/Kconfig             |   3 +
 drivers/base/Makefile            |   1 +
 drivers/base/context_bus.c       |  24 ++++++
 drivers/gpu/host1x/Kconfig       |   5 +-
 drivers/gpu/host1x/Makefile      |   1 -
 drivers/gpu/host1x/context.c     |   2 +-
 drivers/gpu/host1x/context.h     |   3 +-
 drivers/gpu/host1x/context_bus.c |  26 ------
 drivers/iommu/iommu.c            |   6 +-
 drivers/misc/Kconfig             |   1 +
 drivers/misc/fastrpc.c           | 180 +++++++++++++++++++++++++++------------
 include/linux/context_bus.h      |  15 ++++
 12 files changed, 174 insertions(+), 93 deletions(-)
---
base-commit: 1c7cc4904160c6fc6377564140062d68a3dc93a0
change-id: 20260414-computebus-e852f994ee25

Best regards,
-- 
Ekansh Gupta <ekansh.gupta@oss.qualcomm.com>

