From: Igor Velkov <iav@iav.lv>
Subject: [PATCH RFC 0/2] PCI: rockchip-host: Retry training and hot-reset a
 JMB585 on RK3399
Date: Sat, 24 Oct 2026 04:02:42 +0300
Message-Id: <20261024-rockchip-pcie-resume-v1-0-58e54a5cf5f1@iav.lv>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALID3GoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDA0ML3aL85OzkjMwC3YLkzFTdotTi0txUXaNkk5S0VCNjYxPDVCWg1oK
 i1LTMCrCx0UpBbs5KsbW1ACV2BXxrAAAA
To: Shawn Lin <shawn.lin@rock-chips.com>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 Bjorn Helgaas <bhelgaas@google.com>
Cc: Rob Herring <robh@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 linux-pci@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2549; i=iav@iav.lv;
 h=from:subject:message-id; bh=+J4t9tLH+2EYTg30VBIkqM2iIw1DwkZatrHsCOpjmlA=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFl3mLdUexyWM3bhtd3dmaqz3/Kgqe/ei+L8OuciSr6s4
 XuzrdK7o5SFQYyLQVZMkWXCIY1bGUuu/vX3MH8AM4eVCWQIAxenAEyE6RMjw/pZxZP5P9yZPE9w
 XhrzSgbj26LG9x6rZ0lqtWW2tal6bWb4n3bmVo9lnqtt83tVYbtimUMVcsJsIZ6iCuFfJXfonFj
 DDAA=
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

How should the host recover an endpoint that trains the link but does
not answer config requests? On RK3399 that read ends in an external
abort (an SError at probe, a synchronous abort on resume), and the
kernel oopses instead of seeing an absent device.

This happens on a Kobol Helios64 (RK3399, JMicron JMB585 SATA) with
v7.3-rc7 and the mainline DT, in two forms:

- link training times out on resume from s2idle (patch 1);
- the link trains, but a config read of the JMB585 aborts in
  pci_power_up() during resume, and during the bus scan at probe on
  1 of 4 boots (patch 2).

Patch 1 trains again after a timeout. Patch 2 hot-resets the endpoint
after training and waits the 100 ms required after a Conventional
Reset, so every RK3399 probe and resume takes ~105 ms longer.

s2idle with both patches:

  sleep    patch 1 only    both patches
  ~40 s    2 aborts / 30   0 / 100
  ~25 s    1 abort / 11    0 / 40, then 2 aborts in the next 3

In the last of those aborts the link came back 25 ms after the hot
reset instead of 2.8-2.9 ms, and the endpoint did not answer. We could
not reproduce that state on demand.

host_init_port() already pulses PERST# and waits 100 ms before link
training, so config reads start as soon as the link is up. Waiting 1 s
after link-up before the bus scan did not help: 2 of 2 rebinds aborted,
against 2 of 25 without the wait. That test ran without PERST# (the DT
had no ep-gpios).

The data is from the code as posted, except that patch 2 now also fails
probe and resume when the hot reset itself fails; that path was not hit.

Questions:
1. Is an unconditional hot reset after training acceptable, or should
   it depend on the board?
2. Can the host tell before a config read that the endpoint will not
   answer?
3. Is PERST# or a power cycle of the slot the expected recovery from a
   slow link after the hot reset?
4. Should the reset be a Secondary Bus Reset through the Root Port
   rather than PCIE_CLIENT_HOT_RESET_CTRL? We did not try it.

---
Igor Velkov (2):
      PCI: rockchip-host: Retry link training that times out
      PCI: rockchip-host: Hot-reset the endpoint before using the link

 drivers/pci/controller/pcie-rockchip-host.c | 88 ++++++++++++++++++++++++++++-
 drivers/pci/controller/pcie-rockchip.h      |  4 ++
 2 files changed, 89 insertions(+), 3 deletions(-)
---
base-commit: 732c4f7d2c04f8c175d85d9243213783ee024ebc
change-id: 20261018-rockchip-pcie-resume-2c4dfe23341e

Best regards,
-- 
Igor Velkov <iav@iav.lv>

