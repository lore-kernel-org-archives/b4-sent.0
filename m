From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v4 0/3] ath10k: Introduce a devicetree quirk to skip host
 cap QMI requests
Date: Wed, 25 Mar 2026 18:57:14 +0100
Message-Id: <20260325-skip-host-cam-qmi-req-v4-0-bc08538487aa@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAPohxGkC/4XOTW6DMBAF4KtEXnci/2DHZJV7VFkYM8CoMSY2R
 Ukj7l6DVHVVdTPSW8z33otlTISZnQ8vlnChTHEsoXo7MD+4sUegtmQmudRCCA75gyYYYp7BuwD
 3QJDwDii0NtJi41XNyu+UsKPH7r5fS+5SDDAPCd2uCcMF11ZbAaKuTLnQ0wwZxxYwOLqBCzQfp
 8+xpXS50ehSPMbUb/RAeY7puS9e5Fbw37hFAgfeuq6y2tX25C70KLr/Ytu0Rf0Yhiup/zJUMRp
 hlO9OjfJW/Brrun4D2U6Qa0cBAAA=
X-Change-ID: 20251110-skip-host-cam-qmi-req-e155628ebc39
To: Johannes Berg <johannes@sipsolutions.net>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jeff Johnson <jjohnson@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Paul Sajna <sajattack@postmarketos.org>
Cc: Amit Pundir <amit.pundir@linaro.org>, linux-wireless@vger.kernel.org, 
 devicetree@vger.kernel.org, ath10k@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2045; i=david@ixit.cz;
 h=from:subject:message-id; bh=l+Sa6PHie0+76HOU1LeHnQNEt+3sCVhiCKKJMpio3TI=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpxCH7ElA0Nd5DUi8t0QqcUigdI3QY//8k7Dyqz
 jRky/PwpA+JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCacQh+wAKCRBgAj/E00kg
 coh6D/9AsFFPwvKeFoEmXBxHBif+w1qdamrOK/Ez4rcrIsTVlItX5wcf0yvYzIqKrSlCUphp+VT
 Z6Yhj3aT2UZvsS3qgXPwQtHqaTEAeHRgFzYq+pAgPat953/4tI4TS1ca0EsFIw0WDLU4R6THF/L
 74IB2IPQHC9kjNEDJemH9hrq9pFljUIVClfY3v/BQ4jocazqY50lMqIoKiGORKAR0+tNmGZQ14J
 z/MCGoE+aFkpa2sT0Y4ZvE3fh3i0XmKd/WPtH/hxvvXtvrEYHGzeCe+eXYkKpcAuA26837an0fw
 dvTgC+XehXWRTASnhgWZxS1IcFizrAIUub9JNw00qjZuGTrJKuQ7GJWCPlgzMX9XxL3hrbLS+t3
 st4RAVjGZ0+dDqS9Syh/3ARmo28jsHaC3StTM1NfLWmiizOz+O5BxfmRs0YHC3p+z/bVyGM9Clz
 v3+aBR58MiZojkFjYR41592dQNzxwRbRcru4lvvNY1plFKADVL7DeFPMMD/aNKfHEi4tqN6cKwV
 3DK8BW41yVsw9djWl8S0s08GLaUDKTQMTKB2SB12bQ/KguMb3yLYLfPWywonmPBdRJbqQ9IwhrV
 NOFr72aIKW0pWa5PAHFt6rdFamToZHz2vZV4Ekk9SWRiF2tr2jezhkOyFA+Kyu1Lk8YrADVRj0G
 sA0j4vvHSlRZIlA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This quirk is used so far used on:
 - LG G7 ThinQ
 - Xiaomi Poco F1

I'm resending it after ~ 4 years since initial send due to Snapdragon
845 being one of best supported platform for mobile phones running
Linux, so it would be shame to not have shiny support.

Original thread:
  https://lore.kernel.org/all/b796bfee-b753-479a-a8d6-ba1fe3ee6222@ixit.cz/

I tried the embedding the information inside the firmware, but the
information is required *before* loading the firmware itself.
Firmware quirk thread:
  https://lore.kernel.org/linux-wireless/20251111-xiaomi-beryllium-firmware-v1-0-836b9c51ad86@ixit.cz/

Until merged, available also at:
  https://codeberg.org/sdm845/linux/commits/branch/b4/skip-host-cam-qmi-req

Signed-off-by: David Heidelberg <david@ixit.cz>
---
Changes in v4:
- Added my own missing SoB. (Dmitry)
- Improve the commit message. (Dmitry)
- Link to v3: https://lore.kernel.org/r/20260325-skip-host-cam-qmi-req-v3-0-b163cf7b3c81@ixit.cz

Changes in v3:
- Rebased on recent linux-next (next-20260325).
- Improved motivation and description. (Dmitry)
- Link to v2: https://lore.kernel.org/r/20251110-skip-host-cam-qmi-req-v2-0-0daf485a987a@ixit.cz

---
Amit Pundir (3):
      dt-bindings: wireless: ath10k: Add quirk to skip host cap QMI requests
      ath10k: Add device-tree quirk to skip host cap QMI requests
      arm64: dts: qcom: sdm845-xiaomi-beryllium: Enable ath10k host-cap skip quirk

 .../devicetree/bindings/net/wireless/qcom,ath10k.yaml       |  6 ++++++
 .../arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi |  1 +
 drivers/net/wireless/ath/ath10k/qmi.c                       | 13 ++++++++++---
 drivers/net/wireless/ath/ath10k/snoc.c                      |  3 +++
 drivers/net/wireless/ath/ath10k/snoc.h                      |  1 +
 5 files changed, 21 insertions(+), 3 deletions(-)
---
base-commit: 85964cdcad0fac9a0eb7b87a0f9d88cc074b854c
change-id: 20251110-skip-host-cam-qmi-req-e155628ebc39

Best regards,
-- 
David Heidelberg <david@ixit.cz>

