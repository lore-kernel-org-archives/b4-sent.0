From: Venkat Yadlapati <venkat.yadlapati@yahoo.com>
Subject: [PATCH 0/2] power: supply: qcom_battmgr: Apply the USB host
 current limit early
Date: Mon, 16 Nov 2026 01:50:31 +0530
Message-Id: <20261116-vantage-battmgr-v1-0-7b59157377b7@yahoo.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMyw5AMBCF4VeRWWuiRV1eRSyqBiNR0pZIxLsrl
 t9Jzn+BQ0vooI4usHiQo9UE8DgCPSkzIqM+GEQiJOdcskMZr8LcKe+X0bIqy1EKWZSpziC8Nos
 DnV+xaX+7vZtR+zcD9/0Ac6sFo3MAAAA=
X-Change-ID: 20261116-vantage-battmgr-945e626783c4
To: Sebastian Reichel <sre@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-pm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Joonhoe Kim <26rote@gmail.com>, 
 Venkat Yadlapati <venkat.yadlapati@yahoo.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794774031; l=1416;
 i=venkat.yadlapati@yahoo.com; s=20261023; h=from:subject:message-id;
 bh=4Urtgqt3DqUBR0q/xYpN0Q5CeFpW3WhiyAQifuY4zz4=;
 b=oiAr1lkrlROgaSED6IMbLGrsZ+fPVW8VaNMJWSreoHIIGGaY9xwgB7oKgKlEd4IjI45ZQ0pP1
 LsQJaq6q3AHACFCYc6r/sRcUeGE8sn886WSTMx13ueeyHkFvUkrDWwc
X-Developer-Key: i=venkat.yadlapati@yahoo.com; a=ed25519;
 pk=e8KStCtEMvUP1Se/riB/KVnDAQFEVR2Dw2PcuA8/eME=
X-Endpoint-Received: by B4 Relay for venkat.yadlapati@yahoo.com/20261023 with auth_id=1303
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On the Motorola Signature the battery manager firmware keeps the input
current limit of a USB host port at the 100 mA allowed before
enumeration, so the phone discharges while it is connected to a
computer. The dwc3 controller reports the current the host grants
through usb-psy-name, and commit be5e7367bceb made the limit writable.

The controller reports it before the battery manager service is up
though, so the first patch keeps the limit and applies it once the
service comes up. The second one applies it only to SDP, CDP and USB PD
ports, like the downstream driver, so a dedicated charger is never
throttled to what the controller reports.

Tested on a Motorola Signature: connected to a computer it charges after
enumeration instead of discharging.

I used an LLM (Claude) to help write these patches and their commit
messages. I reviewed all of them and tested the result on the device.

---
Venkat Yadlapati (2):
      power: supply: qcom_battmgr: Apply a USB input current limit set early
      power: supply: qcom_battmgr: Don't limit the input current of chargers

 drivers/power/supply/qcom_battmgr.c | 61 ++++++++++++++++++++++++++++++++-----
 1 file changed, 53 insertions(+), 8 deletions(-)
---
base-commit: 7071d4750856abbc68dfe431acc58a1d45dd42e8
change-id: 20261116-vantage-battmgr-945e626783c4

Best regards,
--  
Venkat Yadlapati <venkat.yadlapati@yahoo.com>

