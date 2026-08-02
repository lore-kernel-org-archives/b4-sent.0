From: Luca Lauro <famlauro93l@gmail.com>
Date: Sun, 02 Aug 2026 15:16:22 +0200
Subject: [PATCH v3 06/15] commands: add fan control command
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260802-rn102-rn104-series-v3-6-f7685a279fb5@gmail.com>
References: <20260802-rn102-rn104-series-v3-0-f7685a279fb5@gmail.com>
In-Reply-To: <20260802-rn102-rn104-series-v3-0-f7685a279fb5@gmail.com>
To: Sascha Hauer <s.hauer@pengutronix.de>, 
 "open list:BAREBOX" <barebox@lists.infradead.org>
Cc: Luca Lauro <famlauro93l@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785676613; l=12962;
 i=famlauro93l@gmail.com; s=20260723; h=from:subject:message-id;
 bh=Vx+EBxJNOF0R9x/bZxWmoZX0N9e3iS2sDuPQD/S/D/U=;
 b=L7agvC2v7i9EvrGQaIQ7iaVG84emtv3ntXCkWoA1JqPVJHaFZL3eQGLdNdtizL3/Cb9/v4QGW
 NHVlYjSht9/C9gtaW4TTpVYa5DmWZ4m2oKSqk4SSsjMax5NgLzSvVkn
X-Developer-Key: i=famlauro93l@gmail.com; a=ed25519;
 pk=OAJlcD69ugQCl99Vy6w+Aeu+ZUb1IVGcz1Ijxo6Ch78=
X-Endpoint-Received: by B4 Relay for famlauro93l@gmail.com/20260723 with auth_id=892
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Luca Lauro <famlauro93l@gmail.com>
---
 commands/Kconfig  |   7 ++
 commands/Makefile |   2 +
 commands/fan.c    | 286 ++++++++++++++++++++++++++++++++++++++++++++++++++++++
 3 files changed, 295 insertions(+)

diff --git a/commands/Kconfig b/commands/Kconfig
index 297c89b4b5..d661f0eaab 100644
--- a/commands/Kconfig
+++ b/commands/Kconfig
@@ -2337,6 +2337,13 @@ config CMD_RKSECURE
 	  The rksecure command allows to retrieve information about and enable
 	  secure boot for Rockchip rk3588 SoCs.
 
+config CMD_FAN
+	bool
+	depends on FAN
+	prompt "fan command"
+	help
+	  Control and monitor target fans.
+
 # end Hardware manipulation commands
 endmenu
 
diff --git a/commands/Makefile b/commands/Makefile
index 2563efb12f..227c40b3f5 100644
--- a/commands/Makefile
+++ b/commands/Makefile
@@ -173,4 +173,6 @@ obj-$(CONFIG_CMD_DMSETUP)	+= dmsetup.o
 obj-$(CONFIG_CMD_VERITYSETUP)	+= veritysetup.o
 obj-$(CONFIG_CMD_SCONFIG)	+= sconfig.o
 obj-$(CONFIG_CMD_RKSECURE)	+= rksecure.o
+obj-$(CONFIG_CMD_FAN)		+= fan.o
+
 UBSAN_SANITIZE_ubsan.o := y
diff --git a/commands/fan.c b/commands/fan.c
new file mode 100644
index 0000000000..613b4ac101
--- /dev/null
+++ b/commands/fan.c
@@ -0,0 +1,286 @@
+#include <common.h>
+#include <command.h>
+#include <complete.h>
+#include <errno.h>
+#include <fan/fan.h>
+
+static int do_fan(int argc, char *argv[])
+{
+	struct fan_device *fan;
+	char buf[32];
+	unsigned long val;
+	int ret = 0;
+
+
+	if (argc < 3) {
+		return COMMAND_ERROR_USAGE;
+	}
+
+	fan = fan_device_find(argv[2]);
+	if (IS_ERR(fan)) {
+		printf("Device not found: %s\n", argv[2]);
+		return PTR_ERR(fan);
+	}
+	if (!fan->ops) {
+		printf("Fan driver ops not initialized\n");
+		return -ENODEV;
+	}
+
+	if (!strcmp(argv[1], "get")) {
+		if (argc == 4) {
+			if (!strcmp(argv[3], "startv") && fan->ops->get_fan_startv) {
+				ret = fan->ops->get_fan_startv(fan->dev, buf);
+				printf("Fan startup voltage mode: %s\n", ret >= 0 ? buf : "N/A");
+			}
+			else if (!strcmp(argv[3], "gearmult") && fan->ops->get_gear_multiplier) {
+				ret = fan->ops->get_gear_multiplier(fan->dev, buf);
+				printf("Gear multiplier: %s\n", ret >= 0 ? buf : "N/A");
+}
+			else if (!strcmp(argv[3], "outmode") && fan->ops->get_output_mode) {
+				ret = fan->ops->get_output_mode(fan->dev, buf);
+				printf("Output mode: %s\n", ret >= 0 ? buf : "N/A");
+			}
+			else if (!strcmp(argv[3], "ppr") && fan->ops->get_fan_ppr) {
+				ret = fan->ops->get_fan_ppr(fan->dev, buf);
+				printf("Pulses per revolution: %s\n", ret >= 0 ? buf : "N/A");
+			}
+			else if (!strcmp(argv[3], "pwmpol") && fan->ops->get_pwm_polarity) {
+				ret = fan->ops->get_pwm_polarity(fan->dev, buf);
+				printf("PWM polarity: %s\n", ret >= 0 ? buf : "N/A");
+			}
+			else if (!strcmp(argv[3], "clkfreq") && fan->ops->get_clk_freq) {
+				ret = fan->ops->get_clk_freq(fan->dev, buf);
+				printf("Clock frequency: %s\n", ret >= 0 ? buf : "N/A");
+			}
+			else if (!strcmp(argv[3], "clkdiv") && fan->ops->get_clk_div) {
+				ret = fan->ops->get_clk_div(fan->dev, buf);
+				printf("Clock divider: %s\n", ret >= 0 ? buf : "N/A");
+			}
+			else if (!strcmp(argv[3], "ctrlmode") && fan->ops->get_control_mode) {
+				ret = fan->ops->get_control_mode(fan->dev, buf);
+				printf("Control mode: %s\n", ret >= 0 ? buf : "N/A");
+			}
+			else if (!strcmp(argv[3], "outmode") && fan->ops->get_output_mode) {
+				ret = fan->ops->get_output_mode(fan->dev, buf);
+				printf("Output mode: %s\n", ret >= 0 ? buf : "N/A");
+			}
+			else if (!strcmp(argv[3], "oocdet") && fan->ops->get_ooc_detection) {
+				ret = fan->ops->get_ooc_detection(fan->dev, buf);
+				printf("Out of control detection: %s\n", ret >= 0 ? buf : "N/A");
+			}
+			else if (!strcmp(argv[3], "faultdet") && fan->ops->get_failure_detection) {
+				ret = fan->ops->get_failure_detection(fan->dev, buf);
+				printf("Failure detection: %s\n", ret >= 0 ? buf : "N/A");
+			}
+			else if (!strcmp(argv[3], "oocstate") && fan->ops->get_ooc_state) {
+				ret = fan->ops->get_ooc_state(fan->dev, buf);
+				printf("Fan out of control state: %s\n", ret >= 0 ? buf : "N/A");
+			}
+			else if (!strcmp(argv[3], "faultstate") && fan->ops->get_failure_state) {
+				ret = fan->ops->get_failure_state(fan->dev, buf);
+				printf("Fan failure state: %s\n", ret >= 0 ? buf : "N/A");
+			}
+			else if (!strcmp(argv[3], "speed") && fan->ops->get_fan_speed) {
+				ret = fan->ops->get_fan_speed(fan->dev, buf);
+				printf("Fan speed: %s\n", ret >= 0 ? buf : "N/A");
+			}
+			else if (!strcmp(argv[3], "rpm") && fan->ops->get_fan_rpm) {
+				ret = fan->ops->get_fan_rpm(fan->dev, buf);
+				printf("Fan rpm: %s\n", ret >= 0 ? buf : "N/A");
+			}
+			else if (!strcmp(argv[3], "level") && fan->ops->get_fan_level) {
+				ret = fan->ops->get_fan_level(fan->dev, buf);
+				printf("Fan level: %s\n", ret >= 0 ? buf : "N/A");
+			}
+			else if (!strcmp(argv[3], "all")) {
+				if (fan->ops->get_fan_startv) {
+					ret = fan->ops->get_fan_startv(fan->dev, buf);
+					printf("Fan startup voltage mode: %s\n", ret >= 0 ? buf : "N/A");
+				}
+				if (fan->ops->get_gear_multiplier) {
+					ret = fan->ops->get_gear_multiplier(fan->dev, buf);
+					printf("Gear multiplier: %s\n", ret >= 0 ? buf : "N/A");
+				}
+				if (fan->ops->get_fan_ppr) {
+					ret = fan->ops->get_fan_ppr(fan->dev, buf);
+					printf("Pulses per revolution: %s\n", ret >= 0 ? buf : "N/A");
+				}
+				if (fan->ops->get_pwm_polarity) {
+					ret = fan->ops->get_pwm_polarity(fan->dev, buf);
+					printf("PWM polarity: %s\n", ret >= 0 ? buf : "N/A");
+				}
+				if (fan->ops->get_clk_freq) {
+					ret = fan->ops->get_clk_freq(fan->dev, buf);
+					printf("Clock frequency: %s\n", ret >= 0 ? buf : "N/A");
+				}
+				if (fan->ops->get_clk_div) {
+					ret = fan->ops->get_clk_div(fan->dev, buf);
+					printf("Clock divider: %s\n", ret >= 0 ? buf : "N/A");
+				}
+				if (fan->ops->get_control_mode) {
+					ret = fan->ops->get_control_mode(fan->dev, buf);
+					printf("Control mode: %s\n", ret >= 0 ? buf : "N/A");
+				}
+				if (fan->ops->get_output_mode) {
+					ret = fan->ops->get_output_mode(fan->dev, buf);
+					printf("Output mode: %s\n", ret >= 0 ? buf : "N/A");
+				}
+				if (fan->ops->get_ooc_detection) {
+					ret = fan->ops->get_ooc_detection(fan->dev, buf);
+					printf("Out of control detection: %s\n", ret >= 0 ? buf : "N/A");
+				}
+				if (fan->ops->get_failure_detection) {
+					ret = fan->ops->get_failure_detection(fan->dev, buf);
+					printf("Failure detection: %s\n", ret >= 0 ? buf : "N/A");
+				}
+				if (fan->ops->get_failure_state) {
+					ret = fan->ops->get_failure_state(fan->dev, buf);
+					printf("Fan failure state: %s\n", ret >= 0 ? buf : "N/A");
+				}
+				if (fan->ops->get_ooc_state) {
+					ret = fan->ops->get_ooc_state(fan->dev, buf);
+					printf("Fan out of control state: %s\n", ret >= 0 ? buf : "N/A");
+				}
+				if (fan->ops->get_fan_speed) {
+					ret = fan->ops->get_fan_speed(fan->dev, buf);
+					printf("Fan speed: %s\n", ret >= 0 ? buf : "N/A");
+				}
+				if (fan->ops->get_fan_rpm) {
+					ret = fan->ops->get_fan_rpm(fan->dev, buf);
+					printf("Fan rpm: %s\n", ret >= 0 ? buf : "N/A");
+				}
+				if (fan->ops->get_fan_level) {
+					ret = fan->ops->get_fan_level(fan->dev, buf);
+					printf("Fan level: %s\n", ret >= 0 ? buf : "N/A");
+				}
+			}
+			else {
+				printf("Invalid parameter: %s\n", argv[3]);
+				return COMMAND_ERROR_USAGE;
+			}
+		}
+		else {
+			printf("Invalid number of arguments for %s cmd\n", argv[1]);
+			return COMMAND_ERROR_USAGE;
+		}
+	}
+	else if (!strcmp(argv[1], "set")) {
+		if (argc == 5) {
+			val = simple_strtoul(argv[4], NULL, 10);
+			snprintf(buf, sizeof(buf), "%lu", val);
+
+			if (!strcmp(argv[3], "startv") && fan->ops->set_fan_startv) {
+				ret = fan->ops->set_fan_startv(fan->dev, val);
+				printf("Fan startup voltage set to: %s\n", ret >= 0 ? buf : "N/A");
+			}
+			else if (!strcmp(argv[3], "gearmult") && fan->ops->set_gear_multiplier) {
+				ret = fan->ops->set_gear_multiplier(fan->dev, val);
+				printf("Gear multiplier set to: %s\n", ret >= 0 ? buf : "N/A");
+			}
+			else if (!strcmp(argv[3], "ppr") && fan->ops->set_fan_ppr) {
+				ret = fan->ops->set_fan_ppr(fan->dev, val);
+				printf("Pulses per revolution set to: %s\n", ret >= 0 ? buf : "N/A");
+			}
+			else if (!strcmp(argv[3], "pwmpol") && fan->ops->set_pwm_polarity) {
+				ret = fan->ops->set_pwm_polarity(fan->dev, val);
+				printf("PWM polarity set to: %s\n", ret >= 0 ? buf : "N/A");
+			}
+			else if (!strcmp(argv[3], "clkfreq") && fan->ops->set_clk_freq) {
+				ret = fan->ops->set_clk_freq(fan->dev, val);
+				printf("Clock frequency set to: %s\n", ret >= 0 ? buf : "N/A");
+			}
+			else if (!strcmp(argv[3], "clkdiv") && fan->ops->set_clk_div) {
+				ret = fan->ops->set_clk_div(fan->dev, val);
+				printf("Clock divider set to: %s\n", ret >= 0 ? buf : "N/A");
+			}
+			else if (!strcmp(argv[3], "ctrlmode") && fan->ops->set_control_mode) {
+				ret = fan->ops->set_control_mode(fan->dev, val);
+				printf("Control mode set to: %s\n", ret >= 0 ? buf : "N/A");
+			}
+			else if (!strcmp(argv[3], "outmode") && fan->ops->set_output_mode) {
+				ret = fan->ops->set_output_mode(fan->dev, val);
+				printf("Output mode set to: %s\n", ret >= 0 ? buf : "N/A");
+			}
+			else if (!strcmp(argv[3], "ooc") && fan->ops->set_ooc_detection) {
+				ret = fan->ops->set_ooc_detection(fan->dev, val);
+				printf("Out of control detection set to: %s\n", ret >= 0 ? buf : "N/A");
+			}
+			else if (!strcmp(argv[3], "fault") && fan->ops->set_failure_detection) {
+				ret = fan->ops->set_failure_detection(fan->dev, val);
+				printf("Failure detection set to: %s\n", ret >= 0 ? buf : "N/A");
+			}
+			else if (!strcmp(argv[3], "speed") && fan->ops->set_fan_speed) {
+				ret = fan->ops->set_fan_speed(fan->dev, val);
+				printf("Fan speed set to: %s\n", ret >= 0 ? buf : "N/A");
+			}
+			else if (!strcmp(argv[3], "rpm") && fan->ops->set_fan_rpm) {
+				ret = fan->ops->set_fan_rpm(fan->dev, val);
+				printf("Fan rpm set to: %s\n", ret >= 0 ? buf : "N/A");
+			}
+			else if (!strcmp(argv[3], "level") && fan->ops->set_fan_level) {
+				ret = fan->ops->set_fan_level(fan->dev, val);
+				printf("Fan level set to: %s\n", ret >= 0 ? buf : "N/A");
+			}
+			else {
+				printf("Invalid parameter: %s\n", argv[3]);
+				return COMMAND_ERROR_USAGE;
+			}
+		}
+		else {
+			printf("Invalid number of arguments for %s cmd\n", argv[1]);
+			return COMMAND_ERROR_USAGE;
+		}
+	}
+	else if (!strcmp(argv[1], "init")) {
+		if (argc == 3) {
+			if (fan->ops->fan_init) {
+				ret = fan->ops->fan_init(fan->dev);
+				printf("Fan initialization: %s\n", ret >= 0 ? "successful" : "N/A");
+			}
+		}
+		else {
+			printf("Invalid number of arguments for %s cmd\n", argv[1]);
+			return COMMAND_ERROR_USAGE;
+		}
+	}
+	else {
+			printf("Invalid cmd: %s\n", argv[1]);
+			return COMMAND_ERROR_USAGE;
+	}
+
+	return ret;
+}
+
+BAREBOX_CMD_HELP_START(fan)
+BAREBOX_CMD_HELP_TEXT("cmd options:\n")
+BAREBOX_CMD_HELP_OPT("get", "get fan parameter")
+BAREBOX_CMD_HELP_OPT("set", "set fan parameter")
+BAREBOX_CMD_HELP_OPT("init", "initialize fan")
+
+BAREBOX_CMD_HELP_TEXT("\nparameter options:\n")
+BAREBOX_CMD_HELP_OPT("outmode", "fan controller ouptut mode [0 (adc)|1 (pwm)]")
+BAREBOX_CMD_HELP_OPT("clkdiv", "fan controller prescaler value [1|2|4|8]")
+BAREBOX_CMD_HELP_OPT("clkfreq", "input clock frequency (Hz)")
+BAREBOX_CMD_HELP_OPT("ppr", "fan tachometer pulses per revolution [2|4]")
+BAREBOX_CMD_HELP_OPT("ctrlmode", "fan control mode [0 (open-loop)|1 (closed-loop)]")
+BAREBOX_CMD_HELP_OPT("speed", "fan speed register value [0:255]")
+BAREBOX_CMD_HELP_OPT("rpm", "fan rpm [0:(max fan rpm)]")
+BAREBOX_CMD_HELP_OPT("level", "fan speed percentage [0:100]")
+BAREBOX_CMD_HELP_OPT("startv", "fan startup voltage [0|1|2|3]")
+BAREBOX_CMD_HELP_OPT("gearmult", "gear multiplier [0|1|2]")
+BAREBOX_CMD_HELP_OPT("pwmpol", "PWM polarity [0 (positive)|1 (negative)]")
+BAREBOX_CMD_HELP_OPT("faultdet", "enable/disable failure detection [0|1]")
+BAREBOX_CMD_HELP_OPT("oocdet", "enable/disable out-of-control detection [0|1]")
+BAREBOX_CMD_HELP_OPT("fault", "fan failure flag [0 (ok)|1 (fault)]")
+BAREBOX_CMD_HELP_OPT("ooc", "fan out of control flag [1 (ok):0 (ooc)]")
+BAREBOX_CMD_HELP_OPT("all", "print all fan parameters")
+BAREBOX_CMD_HELP_TEXT("\n")
+BAREBOX_CMD_HELP_END
+
+BAREBOX_CMD_START(fan)
+	.cmd		= do_fan,
+	BAREBOX_CMD_DESC("fan management")
+	BAREBOX_CMD_OPTS("<cmd> <devpath> <parameter> [value]")
+	BAREBOX_CMD_GROUP(CMD_GRP_HWMANIP)
+	BAREBOX_CMD_HELP(cmd_fan_help)
+BAREBOX_CMD_END
\ No newline at end of file

-- 
2.47.3

