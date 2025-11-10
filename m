From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v2 0/3] ath10k: Introduce a devicetree quirk to skip host
 cap QMI requests
Date: Mon, 10 Nov 2025 15:26:23 +0100
Message-Id: <20251110-skip-host-cam-qmi-req-v2-0-0daf485a987a@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAA/2EWkC/x3MQQ6CMBCF4auYrh3SqZaAK+9hXFQYYCJtYVqNC
 eHuNmxe8i3ev6lEwpTU7bQpoS8njqHAnE+qm1wYCbgvVkYbi4ga0psXmGLK0DkPq2cQWoHQ2to
 09OourSrfRWjg39F9PIsHiR7yJOSOGtYatW1sg4DttS4LI2dIFHog73gG5zlXyyf0LPeZg5NYR
 RnVvv8BHXRHebIAAAA=
X-Change-ID: 20251110-skip-host-cam-qmi-req-e155628ebc39
To: Johannes Berg <johannes@sipsolutions.net>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jeff Johnson <jjohnson@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-wireless@vger.kernel.org, devicetree@vger.kernel.org, 
 ath10k@lists.infradead.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>, Amit Pundir <amit.pundir@linaro.org>, 
 Bjorn Andersson <andersson@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1577; i=david@ixit.cz;
 h=from:subject:message-id; bh=L3nGmc65cfsV6qiQ+LYogmLlv8XDTxddUlOLJY174z8=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpEfYS7iCjxoLP0PYyTp6kzSTKLNz3Min/kJQM+
 +zutAUqZSOJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaRH2EgAKCRBgAj/E00kg
 cmr0D/44yLirU8sAm10sSfdpjaByLaHLJ31fqEwiWiOfg1nSaysGs2tB9VxmWhkb7aBtP1IVBQ0
 lgZDpZQ9MbxExySnG4MRztMmXK0Fta/fA+Ng7VW754pQYzDxBWEUwjdOPsrfXOZ/PfbGdPVkN1W
 L2p3LEgCkB9zBQ0WddnxTRNFKwBrYgySEAk/qjHZeIX/aD25Jr8IpRrGtkMgOstpwkkwhXmxR1y
 ThsRwgeglDN4/PndoiIo01PO/YzUNCASLCgh/WWd4E8QSQuQ7+zPmVOHzjtXxVUKaeiiIzDK3Jh
 zzYIJAnG8m5bash9NwGW9MSpwudewo5lxV+9/wAbk/E9Ol+uHf14Q/jW0xb40yTWLHNJDbtwfEm
 ZXuyjVg2tlKVrZi+hmrI58OkD2VYjuIGm9OH+jdkCwZyAyoKxHE471m/qaZcZ27wB54J68IPr5n
 QuQ744n6lddLMMET0L/jFa82yWBV9vhCouk+WQFX+Wm/1SPedSEMz1NH4ax5Lxeel/I9jX26xnk
 PyCaaQWkAxg5qinGYs+LOLzGNjnfc8ElGRoSJQznPbVtSwZcb62l2U900GSUe7Rhvt+TNDami4j
 Qd79ebuzvzBzMCeylNo4sjsI1PuRrzzifjwYHtPklpa0d9iKG+qRMIHGVEYZWza+5cWDIIx7ZLh
 vvJdMvAfrCGgVAA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This quirk is used so far for Xiaomi Poco F1.

I'm resending it after ~ 4 years since initial send due to Snapdragon
845 being one of best supported platform for mobile phones running
Linux, so it would be shame to not have shiny support.

I'm very much open to suggestions how to solve this in a different way,
as the original discussion thread got quiet, see
  https://lore.kernel.org/all/b796bfee-b753-479a-a8d6-ba1fe3ee6222@ixit.cz/

There could be other devices in need of this quirk, but if they're not,
we could make it compatible specific quirk.

Until merged, available also at:
  https://gitlab.com/dhxx/linux/-/commits/b4/skip-host-cam-qmi-req

Signed-off-by: David Heidelberg <david@ixit.cz>
---
Amit Pundir (3):
      dt-bindings: wireless: ath10k: Introduce quirk to skip host cap QMI requests
      ath10k: Introduce a devicetree quirk to skip host cap QMI requests
      arm64: dts: qcom: sdm845-xiaomi-beryllium: Enable ath10k host-cap skip quirk

 .../devicetree/bindings/net/wireless/qcom,ath10k.yaml       |  6 ++++++
 .../arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi |  2 ++
 drivers/net/wireless/ath/ath10k/qmi.c                       | 13 ++++++++++---
 drivers/net/wireless/ath/ath10k/snoc.c                      |  3 +++
 drivers/net/wireless/ath/ath10k/snoc.h                      |  1 +
 5 files changed, 22 insertions(+), 3 deletions(-)
---
base-commit: ab40c92c74c6b0c611c89516794502b3a3173966
change-id: 20251110-skip-host-cam-qmi-req-e155628ebc39

Best regards,
-- 
David Heidelberg <david@ixit.cz>

