From: Raz Ben Yehuda <raz.benyehuda@mobileye.com>
Date: Sun, 07 Jun 2026 18:45:35 +0300
Subject: [PATCH v2 5/5] MAINTAINERS: Add myself to the list of UFS
 maintainers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260607-ufs_tool2-v2-5-f79ff26ab18c@mobileye.com>
References: <20260607-ufs_tool2-v2-0-f79ff26ab18c@mobileye.com>
In-Reply-To: <20260607-ufs_tool2-v2-0-f79ff26ab18c@mobileye.com>
To: u-boot@lists.denx.de
Cc: Neil Armstrong <neil.armstrong@linaro.org>, 
 Bhupesh Sharma <bhupesh.linux@gmail.com>, 
 Neha Malcom Francis <n-francis@ti.com>, Tom Rini <trini@konsulko.com>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Padmarao Begari <padmarao.begari@amd.com>, 
 Michal Simek <michal.simek@amd.com>, Julien Stephan <jstephan@baylibre.com>, 
 Udit Kumar <u-kumar1@ti.com>, 
 Kunihiko Hayashi <hayashi.kunihiko@socionext.com>, 
 Venkatesh Yadav Abbarapu <venkatesh.abbarapu@amd.com>, 
 Shawn Lin <shawn.lin@rock-chips.com>, Jared McArthur <j-mcarthur@ti.com>, 
 Quentin Schulz <quentin.schulz@cherry.de>, 
 Jerome Forissier <jerome.forissier@arm.com>, 
 Peter Robinson <pbrobinson@gmail.com>, 
 Dinesh Maniyam <dinesh.maniyam@altera.com>, 
 Heiko Schocher <hs@nabladev.com>, Simon Glass <sjg@chromium.org>, 
 briansune <briansune@gmail.com>, Yao Zi <me@ziyao.cc>, 
 Peng Fan <peng.fan@nxp.com>, Kory Maincent <kory.maincent@bootlin.com>, 
 Kuan-Wei Chiu <visitorckw@gmail.com>, 
 Raymond Mao <raymond.mao@riscstar.com>, 
 Stefan Roese <stefan.roese@mailbox.org>, 
 Philip Molloy <philip.molloy@analog.com>, 
 Raz Ben Yehuda <raz.benyehuda@mobileye.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=610;
 i=raz.benyehuda@mobileye.com; h=from:subject:message-id;
 bh=Evo/xayXeA+xDd8mrRtcOpcBO0hiTU23xBCrmgriIpk=;
 b=owEBbQKS/ZANAwAKAZ+a6ZSW6I45AcsmYgBqJZI6hPmU96e5xjH2wDhD4ovRC0jp0prVLpd9x
 TZo46BAlayJAjMEAAEKAB0WIQSC7lz5E3UmOrJvRDqfmumUluiOOQUCaiWSOgAKCRCfmumUluiO
 OZ0FD/9/p1oUL5EWmY++j+5OvAgtOfm33qZ7F1Mpn9dQwuP9S+FRJ9u+2JrO0y2En1qsHbqzZNx
 hJ8JhVoR3RxmwdSZIlKeJAZYqn1f+Gy7uidCDun/971Ta8aJfWiQrbRCjlHtGJlTG3W80DbKFAZ
 0rpKVs6ZXs4XB73bZhkdq7MDnz5+68ih+jOVbbcr6N9KP/5gZAfRELWQFfi6qgYtYoYONaeQS8U
 5MOXi2GoedgNos9rFD+e/VVFkFx9G1yoS/h66iea++ur0bSiVC9gWfH17R8lv8GQDBlLg3ZSq/l
 he6eCQHUW7FXdl0gzjVoVVSe3/Cz1A4yUFLPnDlBVjjhl67VHWtsH3yKf582frNPtsF0jFws7TV
 WkgYCfMAGbs6O0L3tnL4HaWJWObddIeDsLCjMYKbOoncyrI/1mcX8ZSXZzWo3QIVFy6cqiHkDpg
 AVfqYtZEORnx8OxxaQdelIAHZBk2XDxZ3et1zVv7l0zAv6aHRNkgsWIlEwWKl+l9o/Zd8SNAhXW
 FFPpDscOD8Awi/MWalf4Wi1CAGqOind2QEIE9IoKUym7Gh6tVZG8fcIZnzt8yL0yMYqDdA5Y0GS
 1HNNCBFfkk2iPQeJKvb5kEz8/JuU6LdJOtI2KeHG5N2Cn7rgj/Aspw2zgHixyr4G0a1CbOsl8tM
 ExfATacJMQpIqmQ==
X-Developer-Key: i=raz.benyehuda@mobileye.com; a=openpgp;
 fpr=82EE5CF91375263AB26F443A9F9AE99496E88E39
X-Endpoint-Received: by B4 Relay for raz.benyehuda@mobileye.com/default with auth_id=808
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

    Adding myself to ufs.

Signed-off-by: Raz Ben Yehuda <raz.benyehuda@mobileye.com>
---
 MAINTAINERS | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 571af196465..d2257a8327c 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -1920,8 +1920,11 @@ UFS
 M:	Neil Armstrong <neil.armstrong@linaro.org>
 M:	Bhupesh Sharma <bhupesh.linux@gmail.com>
 M:	Neha Malcom Francis <n-francis@ti.com>
+R:	Raz Ben Yehuda <raz.benyehuda@mobileye.com>
 S:	Maintained
+F:	cmd/ufs.c
 F:	common/spl/spl_ufs.c
+F:	doc/usage/cmd/ufs.rst
 F:	drivers/ufs/
 
 UPL

-- 
2.43.0

