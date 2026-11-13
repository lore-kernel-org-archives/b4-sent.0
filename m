From: Ghennadi Procopciuc <ghennadi.procopciuc@oss.nxp.com>
Subject: [PATCH RFC 0/2] firmware: arm_scmi: clock: stop discovering every
 clock at boot
Date: Fri, 13 Nov 2026 15:27:45 +0200
Message-Id: <20261113-b4-scmi-clk-on-demand-v1-0-7fd162097b57@oss.nxp.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFIQ92oC/yWMzQrCMBAGX6V8ZxeaGqv1KvgAXsVDflZdtalkV
 YTSdzfqcQZmRihnYcW6GpH5JSpDKmBmFcLZpROTxMJo6qY1xszJW9LQC4XblYZEkXuXIi2WtnM
 t193KW5T2nvko7993j912g8Nf6tNfODy+R0zTByfIzQl+AAAA
X-Change-ID: 20261113-b4-scmi-clk-on-demand-5749a6e098b4
To: Brian Masney <bmasney+clk@redhat.com>, 
 Sudeep Holla <sudeep.holla@kernel.org>, Stephen Boyd <sboyd@kernel.org>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, 
 Cristian Marussi <cristian.marussi@arm.com>
Cc: linux-doc@vger.kernel.org, Alberto Ruiz <aruizrui@redhat.com>, 
 linux-arm-kernel@lists.infradead.org, Christophe Lizzi <clizzi@redhat.com>, 
 linux-clk@vger.kernel.org, linux-kernel@vger.kernel.org, 
 arm-scmi@vger.kernel.org, Eric Chanudet <echanude@redhat.com>, 
 Enric Balletbo <eballetb@redhat.com>, NXP S32 Linux Team <s32@nxp.com>, 
 Jonathan Corbet <corbet@lwn.net>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794576479; l=7652;
 i=ghennadi.procopciuc@oss.nxp.com; s=20261113; h=from:subject:message-id;
 bh=gZgo2l01v/+zPm3N88ysUMp9g86TRzNGPYo8Hm6Qk38=;
 b=9AWQ7Q2v3OeyoO3YTe7FJBR77MmPpmc1ggiEMtaHHuI4QIyO91hZuUaZzWFcMP8zWie1IbxOY
 jpOEuuJuf+3AazK8/0su5lhkhraXfu9ORUhf67LNP2x5doPVHfPgng4
X-Developer-Key: i=ghennadi.procopciuc@oss.nxp.com; a=ed25519;
 pk=hNLk4ZpONFOVJg3NdDWRU2LtaL+HBg4W2I1KU0+XBmo=
X-Endpoint-Received: by B4 Relay for ghennadi.procopciuc@oss.nxp.com/20261113 with auth_id=1509
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi all,

At probe, the SCMI clock protocol and clk-scmi discover and register
every clock the platform reports, whether or not a Linux consumer
references it. On platforms that report hundreds of clocks, this can
add tens of milliseconds or more to every boot.

This is sent as RFC to get feedback on the direction before a final
version. The questions are listed at the end.

The problem
===========

For each clock, probe sends a fixed number of messages:

  - CLOCK_ATTRIBUTES, in scmi_clock_protocol_init()
  - CLOCK_GET_PERMISSIONS, if the platform supports it
  - CLOCK_DESCRIBE_RATES, at least once even with the bounded iterators
  - CLOCK_POSSIBLE_PARENTS_GET and CLOCK_NAME_GET, when applicable
  - CLOCK_RATE_GET, from __clk_core_init() at registration

The total cost is about N_clocks x messages_per_clock x message_latency.
It grows with the number of clocks the platform reports, not with the
number of clocks Linux uses. Three properties make it worth addressing:

1. It is paid on every boot. The result does not change between boots
   with the same firmware, but nothing is cached. Every cold boot, warm
   reboot or kexec pays it again, and so does every VM that has its own
   SCMI clock provider.

2. It is on the critical path. scmi_clocks_probe() runs synchronously
   and registers the provider only at the end. Every consumer of an SCMI
   clock waits for the whole set to be discovered, and through fw_devlink
   so do the devices that depend on those consumers. A storage controller
   that needs one clock to mount the root filesystem waits for hundreds.

3. Most of the work is for clocks Linux has no use for. SoCs that run
   several agents or partitions on one SCMI server often report the full
   clock space to every agent. An agent may have only a dozen clocks
   referenced in its device tree, and may not even be allowed to control
   the others, but it still discovers and registers all of them.

clk_disable_unused() adds to this. It walks every registered clock and,
for clocks with an is_prepared op, sends CLOCK_CONFIG_GET for each one,
including clocks Linux can never disable.

An example: NXP S32N79
======================

S32N79 is one platform where the problem shows up. It is used here only
because it was the platform at hand for measurements; any platform with
a large SCMI clock space and a non-trivial message latency has the same
profile.

  - Transport: arm,scmi-smc, one channel, SCMI clock protocol v2.1.
  - The platform reports 432 clocks to the Linux agent.
  - The device tree references 4 of them.
  - All 432 have state, rate and parent control forbidden for this agent.

Before this series:

  Window                                Messages   Time in SCMI
  ------------------------------------  --------   ------------
  protocol init (devm_protocol_get)         1300       76.7 ms
    CLOCK_ATTRIBUTES                         432       26.2 ms
    CLOCK_DESCRIBE_RATES                     432       25.8 ms
    CLOCK_GET_PERMISSIONS                    432       24.5 ms
    version and attributes                     4        0.2 ms
  registration + __clk_core_init()           432       26.0 ms
    CLOCK_RATE_GET                           432       26.0 ms
  scmi_clocks_probe() total                 1732      102.7 ms
                                                     (103.5 ms wall)
  clk_disable_unused()                       432       25.8 ms
    CLOCK_CONFIG_GET                         432       25.6 ms
    CLOCK_CONFIG_SET                           0

  - The average cost of a message is about 59 us, and it is about the
    same for every message type, so the fixed per-call cost of the
    transport and firmware dominates.
  - About 99% of the probe time is spent waiting for the platform.
  - The clk_disable_unused() pass sends 432 queries and then disables
    nothing, because no clock can be gated by this agent.
  - Together that is about 129 ms of SCMI clock traffic before user
    space starts, for 4 clocks that are actually used.

Expected with this series and dt_referenced_only=1:

  Window                                Messages   Time (expected)
  ------------------------------------  --------   ---------------
  scmi_clocks_probe()                         72       ~4.3 ms
  clk_disable_unused()                        17       ~1.0 ms

The proposed solution
=====================

The idea is to stop discovering the clocks that Linux does not use. It
takes two steps:

  - The SCMI clock protocol discovers a clock the first time a caller
    uses it, instead of discovering all of them at protocol init.
  - On request, clk-scmi registers only the clocks referenced by
    enabled device tree nodes, plus their parents. The other clocks
    are never discovered. This mode is off by default and is enabled
    with the dt_referenced_only module parameter.

TI's sci-clk already does something similar: it registers only the
clocks referenced in the device tree, with a Kconfig option to probe all
of them from firmware instead (commit 8e48b33f9def, "clk: keystone:
sci-clk: probe clocks from DT instead of firmware").

What dt_referenced_only gives up:

  - clk_summary and debugfs list only the registered clocks.
  - Disabled nodes are skipped, as in sci-clk. A device tree overlay
    that references an SCMI clock ID not present at probe time, or that
    enables a disabled node, is not supported yet. Support can be added
    if this approach is agreed on.
  - A clock referenced only from a property other than "clocks",
    "assigned-clocks" and "assigned-clock-parents" is not registered.

What discovery on first use gives up, with and without
dt_referenced_only:

  - No clock is discovered yet when the protocol events are registered,
    so the support for the rate notifications is checked per clock only
    when a notifier is enabled. A notifier for an event that the
    platform implements, but that no clock supports, is no longer
    rejected with -EOPNOTSUPP at registration. It fails with -EINVAL
    when it is enabled, after the clocks it covers are discovered. No
    in-tree driver registers SCMI clock notifiers. This can be addressed
    if this approach is agreed on.

Questions
=========

The aim of this RFC is to agree on the direction first. The details of
the implementation can follow in a later version.

1. Is it acceptable to discover and register only the SCMI clocks that
   the device tree references, instead of every clock the platform
   reports?

2. If so, should this stay in SCMI, or become a generic mechanism in the
   clock framework that other firmware-backed clock providers can share?

Any feedback, including "this should be done differently", is welcome.

Thanks,
Ghennadi

---
Ghennadi Procopciuc (2):
      firmware: arm_scmi: clock: discover clock domains on first use
      clk: scmi: optionally register only clocks referenced in the device tree

 Documentation/admin-guide/kernel-parameters.txt |   7 ++
 drivers/clk/Kconfig                             |  11 ++
 drivers/clk/clk-scmi.c                          | 120 +++++++++++++++++-
 drivers/firmware/arm/scmi/clock.c               | 160 ++++++++++++++++++------
 include/linux/scmi_protocol.h                   |   4 +-
 5 files changed, 254 insertions(+), 48 deletions(-)
---
base-commit: 49c49ca0c4d02848a9576f72c4741c38c5ba09de
change-id: 20261113-b4-scmi-clk-on-demand-5749a6e098b4

Best regards,
--  
Ghennadi Procopciuc <ghennadi.procopciuc@oss.nxp.com>

