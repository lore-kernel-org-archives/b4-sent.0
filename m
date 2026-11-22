From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v2 0/2] rpmsg: glink: Offer wakeup capabilities
Date: Sun, 22 Nov 2026 21:24:17 +0100
Message-Id: <20261122-rpmsg-qcom-glink-v2-0-d60419793095@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/zXMQQ6CMBCF4auQWVvClILgynsYF6VOS2NpcWqMh
 nB3GxOXf/Let0Em9pThVG3A9PLZp1hCHiows46OhL+VBtnIDhEHweuSnXiYtAgXfLyLQesJm16
 21nZQbiuT9e8febmWtlymz5lJ/6G2QTyikgpVPQ7tqHqBwuhAU21SjCmEz7nQmlOd2MG+fwElC
 051pgAAAA==
X-Change-ID: 20251118-rpmsg-qcom-glink-8aab10623ff5
To: Bjorn Andersson <andersson@kernel.org>, 
 Mathieu Poirier <mathieu.poirier@linaro.org>
Cc: Dylan Van Assche <git@dylanvanassche.be>, 
 Casey Connolly <casey.connolly@linaro.org>, linux-arm-msm@vger.kernel.org, 
 linux-remoteproc@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=3470; i=david@ixit.cz;
 h=from:subject:message-id; bh=lTm79sP5N4nCYtqwli3hsRaQG2T1k37aH17D2Pp90kM=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBrA09yN87Arpx4zHDSlaRNnlb7QYe663LjdDuCL
 o27J6X+XTaJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCawNPcgAKCRBgAj/E00kg
 ch5NEAC566yogcpJwCKgrZkbDk+lgF3bYCcnlCI1Hy52FxHt9HS5kpKbZAzq2iE63yvS+6N0kHm
 YoCPGSXr2fRRFqp0kKRATDk+qC1+9PrbEVnRmnzwlckERaAH7Lkk25AXHtqNYh+tqjDYgCoTUZS
 wN8BFhpXqeiTx7iqIHIr3QnOsVgDrDhXVqKDWy3g4e7SEkXdziGukNFVVA2KcaMm9j0Fnh2nh1E
 ec7Pb3Nf6bC/hjaevCMy1a/p5OB9D2V4BL7MNZbZPNMn+w37Ngof20ZaE0z5Zc7cWk/1OaEcESX
 owZtougwnAXtLlYhw2anbY/MLGAZWdSXPnOOoBh/XxPbjXml8dpgnKUgR2i1q+UrLEgGrWjh9Sg
 pC/1DxGYKMMRjzwpYIapUQPNiyeBDzS+urnzjBUQnSBprcy63tSwxLbQ4feRH/59LtJaN6s0e41
 4choAag5jPQi8jmKOva/2kxDWHj1YCiqB8bfvSyX6FYKmnEaTzHiEThvnI/EFGdb1sAdwf1EtQF
 ux0R+bldKNbKpUxgm+8tDlT22QII5SCLQ23Mr7+/5F/NLOIAOLO0x8npNg/Wj+xDtboykNj1a1w
 xTj4RaudHUCzK4Hx8Tz6Sb/xr6tTFj3Lwpq0MrrR8fRlzHgK0WVw0Q7bR/Sp/bQM3ftqk8+MkFG
 6zvmjsxoqjIFoKQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

LLM generated summary of the decision chosen here, feel free to skip to
the changelog.

Trade-offs made:
1. Sysfs power/wakeup switch vs per-socket EPOLLWAKEUP (from v1 review):
 - Chosen: Device-level sysfs power/wakeup (disabled by default).
 - Trade-off: Works immediately with existing userspace (ModemManager, sensor daemons, udev rules) without requiring application changes, at the
cost of channel/endpoint granularity instead of per-socket granularity.
2. Reporting wakeup only inside if (channel->ept.cb) under channel->recv_lock:
 - Chosen: Gate wakeup on an active endpoint callback rather than adding extra synchronization around channel->rpdev.
 - Trade-off: Keeps GLINK locking simple and avoids waking the system for packets that get dropped anyway (no consumer), while holding channel-
>recv_lock across pm_wakeup_hard_event() (a short spinlock path: dev->power.lock -> ws->lock).
3. Solving /dev/rpmsg_ctrlX wakeup in rpmsg_char.c (Patch 2) instead of falling back to channel->rpdev in GLINK:
 - Chosen: Per-endpoint wakeup on /sys/class/rpmsg/rpmsgX/power/wakeup in rpmsg_char.
 - Trade-off: Transport-independent (works for GLINK, SMD, virtio-rpmsg) and covers locally-initiated endpoints that never have a per-channel
channel->rpdev, without complicating GLINK's channel->rpdev lifetime. In return, userspace configures /sys/class/rpmsg/rpmsgX/power/wakeup
after endpoint creation rather than the GLINK bus device, and directly bound rpmsg_chrdev channels expose two independent power/wakeup knobs
(both off by default).
4. Immediate hard wakeup (pm_wakeup_hard_event(), msec = 0) vs timed wakeup (pm_wakeup_event(..., msec)):
 - Chosen: Same as v1 (msec = 0, hard = true).
 - Trade-off: Immediately aborts suspend / wakes s2idle and bumps wakeup_count without holding the system awake for an arbitrary hardcoded
timeout, relying on userspace/suspend managers (e.g. via /sys/power/wakeup_count) not to re-suspend before draining the queued message.
5. Setting wakeup capability after rpmsg_register_device() in GLINK:
 - Chosen: Kept v1's placement in qcom_glink_rx_open().
 - Trade-off: Works via wakeup_sysfs_add() + a KOBJ_CHANGE uevent, though udev rules matching only ACTION=="add" could race with power/wakeup
creation on the GLINK bus device (Patch 2 avoids this for /sys/class/rpmsg/rpmsgX by calling device_set_wakeup_capable() before
cdev_device_add()).

Changes in v2:
 - Use pm_wakeup_hard_event(&channel->ept.rpdev->dev) inside channel->recv_lock
and the channel->ept.cb check to fix the NULL pointer dereference,
dev->power.wakeup/rpdev use-after-free races, and CONFIG_PM_SLEEP=n build.
 - Fix subject prefix ("rpmsg: glink:") and comment typo.
 - Add a follow-up patch enabling per-endpoint wakeup on /dev/rpmsgX in
rpmsg_char so dynamic /dev/rpmsg_ctrlX endpoints can also opt in to wakeup.
 - Link to v1: https://lore.kernel.org/all/20230117142414.983946-1-caleb.connolly@linaro.org/

Signed-off-by: David Heidelberg <david@ixit.cz>
---
Casey Connolly (1):
      rpmsg: glink: Support waking up on channel rx

David Heidelberg (1):
      rpmsg: char: Support waking up on endpoint rx

 drivers/rpmsg/qcom_glink_native.c | 12 ++++++++++++
 drivers/rpmsg/rpmsg_char.c        |  2 ++
 2 files changed, 14 insertions(+)
---
base-commit: 909ef7a9a30fa139e69e555e3606680f5cca7726
change-id: 20251118-rpmsg-qcom-glink-8aab10623ff5

Best regards,
--  
David Heidelberg <david@ixit.cz>

