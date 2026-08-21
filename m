From: Sven Peter <sven@kernel.org>
Subject: [PATCH 0/3] phy: apple: atc: Prepare USB3-via-4 tunneling
Date: Fri, 21 Aug 2026 15:50:26 +0200
Message-Id: <20260821-b4-atcphy-usb4-v1-0-45c0b741e0c0@kernel.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ5AMBCF4avIrDVpG5FyFbHQmjIWSAchjbsrd
 u9bvD8CYyBkqLMIAQ9iWuYElWfgxm4eUFCfDFrqUhqthC1Et7l1vMTOaXvjKykNeqt6SKc1oKf
 zCzbtb97thG57K3DfD4G6K91yAAAA
X-Change-ID: 20260821-b4-atcphy-usb4-f8f9008efb1d
To: Janne Grunau <j@jannau.net>, Neal Gompa <neal@gompa.dev>, 
 Vinod Koul <vkoul@kernel.org>, Neil Armstrong <neil.armstrong@linaro.org>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-phy@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Sven Peter <sven@kernel.org>, Paul Cristian <p4ulcristian@gmail.com>, 
 stable@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=868; i=sven@kernel.org;
 h=from:subject:message-id; bh=mSWx1NCoUEXQwAwUZ0o2hB/XTB0iO2k+EF+a/falyL8=;
 b=owGbwMvMwCXmIlirolUq95LxtFoSQ1ZH+JLUjq0vpsevMmM3en3Byt2qQ+nux96JvjdOZd5Nv
 sR46dOVjlIWBjEuBlkxRZbt++1Nnzx8I7h006X3MHNYmUCGMHBxCsBE1hQxMuxvUL6Z0ilr+sA+
 tP7XEXmpVNaZNzTZL9fu6/v2tZ514kxGho7EyQeVvlR/qsrbZnrY6PS6iba3a2acyMoVWHR6zzW
 DBCYA
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

This short series first fixes an oversight that prevents USB2 from
working when DP AltMode with 4 lanes is used. Then it adds the required
sequence to point dwc3's PIPE interface to the USB4 Native Host
Interface which I plan to submit soon to support USB3-via-USB4 tunnels.

Best,

Sven

Signed-off-by: Sven Peter <sven@kernel.org>
---
Sven Peter (3):
      phy: apple: atc: Support DUMMY PIPEHANDLER state in configure_pipehandler
      phy: apple: atc: Factor out the PIPE mux sequence
      phy: apple: atc: Implement the USB4 pipehandler state

 drivers/phy/apple/atc.c | 91 ++++++++++++++++++++++++++++++++-----------------
 1 file changed, 59 insertions(+), 32 deletions(-)
---
base-commit: 818bebeb63dd6bf5f4e07e145f6cdbace520a34c
change-id: 20260821-b4-atcphy-usb4-f8f9008efb1d

Best regards,
--  
Sven Peter <sven@kernel.org>

