From: Eduardo Pereira Cruz <dreduardocruz@gmail.com>
Date: Sun, 22 Nov 2026 20:40:55 -0300
Subject: [PATCH v5] docs/translations/pt_BR: process: add
 handling-regressions.rst
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261122-handling-regressions-v5-1-cb363b082adf@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/43NTQ6CMBAF4KuQrq0pAwXqynsYFy0dSg0/pkWiI
 dzdFjfGjSzf5M33FuLRWfTklCzE4Wy9HYcQ+CEhdSsHg9TqkAkwKNIUgIaj7uxgqEPj0Me+p4K
 nkitWs4ppEl7vDhv73NjL9ZP9Q92wnqIVG6310+he2+4MsfdnYgbKKHBeasWlEnlxNr203bEee
 xIn5mwPkgUEM81RigpEXv0i+R4kD4gqlGiAlQwE+0bWdX0DZMD+eVQBAAA=
X-Change-ID: 20261122-handling-regressions-951a5b0c080d
To: linux-doc@vger.kernel.org
Cc: danielmaraboo@gmail.com, corbet@lwn.net, skhan@linuxfoundation.org, 
 rdunlap@infradead.org, Eduardo Pereira Cruz <dreduardocruz@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795390854; l=58481;
 i=dreduardocruz@gmail.com; s=20261119; h=from:subject:message-id;
 bh=HRKx9YSM14r6BXBuyN+Heotj/AqmPypA1wOMpv3uG0A=;
 b=ccU+c7QyelplISkbFxFeXQr7gzHzqRp+BJBqCVLTEAWTxr7APTEoD45HZ/yQRkaT72FFDbNBR
 5Wm7ZDsTOZQArTPTf9t2xCtW9QWCH1JL3uUZ5E7y8BkOPaXHH8TDKjQ
X-Developer-Key: i=dreduardocruz@gmail.com; a=ed25519;
 pk=2dtL+BL/x70sROmAvlskv9dbjj274zlPkLBVu4gJJiA=
X-Endpoint-Received: by B4 Relay for dreduardocruz@gmail.com/20261119 with auth_id=1571
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the Brazilian Portuguese translation of the handling regressions
document, which describes what the "no regressions" rule means in
practice for developers: how to bring new regression reports to the
attention of the regression tracker, what to include when fixing them,
and the expectations and best practices around timing and patch flow.

The translation follows the English original as last changed by commit
fdd100ee60a0 ("docs: process: use gender-neutral pronouns") and keeps
the structure of the original: all 38 section headings in the same
order and level, the 60 literal blocks with the regzbot commands, the
65 URLs and the two :ref: roles.

Signed-off-by: Eduardo Pereira Cruz <dreduardocruz@gmail.com>
---
Changes in v5:
- Send the translation as a single patch instead of a three-part series,
  so that no patch modifies lines introduced by another patch of the
  same series.
- Rebuild the list indentation paragraph by paragraph and item by item;
  the previous revision left several list items with broken
  indentation.
- Keep the corrections made in v4 unchanged.
- Link to v4: https://patch.msgid.link/20261122-handling-regressions-v4-0-b6b9f2070290@gmail.com

docs/translations/pt_BR: process: add handling-regressions.rst

This patch adds the Brazilian Portuguese translation of
Documentation/process/handling-regressions.rst, the document that
describes what the "no regressions" rule means in practice for
developers.

The translation follows the original file as last changed by commit
fdd100ee60a0 ("docs: process: use gender-neutral pronouns") and keeps
its structure: section levels, literal blocks, URLs, :ref: roles and the
regzbot commands are preserved verbatim.

The patch also wires the new document into the pt_BR process index.

Changes in v4:
- Join the section titles that were still split over two lines and give
  them a matching underline; one title had also lost its underline.
- Rejoin the two #regzbot command lines whose URL had been moved to the
  following line, which made the command unusable.
- Use a single "::" before literal blocks instead of ":::".

Changes in v3:
- Split the SPDX header back into two comment lines; the previous
  version merged them into one, which breaks the directive.
- Keep each section title on a single line with a matching underline.
- Replace the remaining "etiqueta" and "maintainer" occurrences with
  "tag" and "mantenedor", and use "flag day" consistently.
- Fix wording issues found on review: "nem sequer compila", "versão
  mainline ... de fato" instead of "adequada", and the AppArmor
  sentence.
- Keep proper nouns such as "Maintainers Summit 2024".
---
 .../pt_BR/process/handling-regressions.rst         | 1118 ++++++++++++++++++++
 Documentation/translations/pt_BR/process/index.rst |    1 +
 2 files changed, 1119 insertions(+)

diff --git a/Documentation/translations/pt_BR/process/handling-regressions.rst b/Documentation/translations/pt_BR/process/handling-regressions.rst
new file mode 100644
index 000000000000..e817b155b882
--- /dev/null
+++ b/Documentation/translations/pt_BR/process/handling-regressions.rst
@@ -0,0 +1,1118 @@
+.. SPDX-License-Identifier: (GPL-2.0+ OR CC-BY-4.0)
+.. Consulte o final deste arquivo para informações adicionais de
+.. redistribuição.
+
+Lidando com regressões
+++++++++++++++++++++++
+
+*Nós não causamos regressões* -- este documento descreve o que essa
+"primeira regra do desenvolvimento do kernel Linux" significa na prática
+para os desenvolvedores. Ele complementa
+Documentation/admin-guide/reporting-regressions.rst, que cobre o assunto
+do ponto de vista do usuário; se você nunca leu aquele texto, vá lá e ao
+menos dê uma passada de olhos antes de continuar aqui.
+
+Os pontos essenciais (também conhecidos como "o TL;DR")
+=======================================================
+
+#. Garanta que os inscritos na `lista de discussão de regressões
+   <https://lore.kernel.org/regressions/>`_
+   (regressions@lists.linux.dev) saibam rapidamente de qualquer novo
+   relato de regressão:
+
+    * Ao receber um relato por e-mail que não tenha a lista em CC,
+       inclua-a imediatamente no circuito enviando ao menos um breve
+       "Responder a todos" com a lista em CC.
+
+    * Reencaminhe ou redirecione para a lista qualquer relato enviado em
+       rastreadores de bugs.
+
+#. Faça o robô de acompanhamento de regressões do kernel Linux,
+   "regzbot", acompanhar o problema (isto é opcional, mas recomendado):
+
+    * Para relatos enviados por e-mail, verifique se o autor incluiu uma
+       linha como ``#regzbot introduced: v5.13..v5.14-rc1``. Caso não
+       tenha, envie uma resposta (com a lista de regressões em CC)
+       contendo um parágrafo como o seguinte, que informa ao regzbot
+       quando o problema começou a ocorrer::
+
+       #regzbot ^introduced: 1f2e3d4c5b6a
+
+    * Ao reencaminhar relatos de um rastreador de bugs para a lista de
+       regressões (veja acima), inclua um parágrafo como o seguinte::
+
+       #regzbot introduced: v5.13..v5.14-rc1 #regzbot from: Some N. Ice
+       Human <some.human@example.com> #regzbot monitor:
+       http://some.bugtracker.example.com/ticket?id=123456789
+
+#. Ao enviar correções para regressões, adicione tags "Closes:" à
+   descrição do patch apontando para todos os lugares onde o problema
+   foi relatado, conforme exigido por
+   Documentation/process/submitting-patches.rst e
+   :ref:`Documentation/process/5.Posting.rst <development_posting>`. Se
+   você estiver corrigindo apenas parte do problema que causou a
+   regressão, pode usar tags "Link:" em vez disso. No momento, o regzbot
+   não faz distinção entre as duas.
+
+#. Tente corrigir as regressões rapidamente assim que o culpado for
+   identificado; as correções da maioria das regressões devem ser
+   mescladas em até duas semanas, mas algumas precisam ser resolvidas em
+   dois ou três dias.
+
+
+Detalhes sobre regressões do kernel Linux para desenvolvedores
+==============================================================
+
+
+O básico importante em mais detalhes
+-------------------------------------
+
+
+O que fazer ao receber relatos de regressão
+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+
+Garanta que o rastreador de regressões do kernel Linux e os demais
+inscritos na `lista de discussão de regressões
+<https://lore.kernel.org/regressions/>`_ (regressions@lists.linux.dev)
+saibam de qualquer regressão recém-relatada:
+
+ * Ao receber por e-mail um relato que não tenha a lista em CC, inclua-a
+    imediatamente no circuito enviando ao menos um breve "Responder a
+    todos" com a lista em CC; procure garantir que ela volte a ser
+    incluída caso você responda a uma resposta que a tenha omitido.
+
+ * Se um relato enviado em um rastreador de bugs chegar à sua caixa de
+    entrada, reencaminhe-o ou redirecione-o para a lista. Considere
+    verificar antes os arquivos da lista, no caso de o autor já ter
+    reencaminhado o relato conforme instruído por
+    Documentation/admin-guide/reporting-issues.rst.
+
+Em ambos os casos, considere fazer com que o robô de acompanhamento de
+regressões do kernel Linux, "regzbot", comece a acompanhar o problema
+imediatamente:
+
+ * Para relatos enviados por e-mail, verifique se o autor incluiu um
+    "comando do regzbot" como ``#regzbot introduced: 1f2e3d4c5b6a``.
+    Caso não tenha, envie uma resposta (com a lista de regressões em CC)
+    com um parágrafo como o seguinte::
+
+       #regzbot ^introduced: v5.13..v5.14-rc1
+
+   Isso informa ao regzbot a faixa de versões em que o problema começou
+   a ocorrer; você também pode especificar uma faixa usando commit-ids
+   ou indicar um único commit-id, no caso de o autor ter feito bisseção
+   do culpado.
+
+   Observe o circunflexo (^) antes de "introduced": ele pede ao regzbot
+   que trate o e-mail pai (aquele ao qual você está respondendo) como o
+   relato inicial da regressão que você quer ver acompanhada; isso é
+   importante, pois mais tarde o regzbot vai procurar patches com tags
+   "Closes:" que apontem para o relato nos arquivos em lore.kernel.org.
+
+ * Ao reencaminhar uma regressão relatada em um rastreador de bugs,
+    inclua um parágrafo com estes comandos do regzbot::
+
+       #regzbot introduced: 1f2e3d4c5b6a #regzbot from: Some N. Ice
+       Human <some.human@example.com> #regzbot monitor:
+       http://some.bugtracker.example.com/ticket?id=123456789
+
+   O regzbot então associará automaticamente os patches ao relato que
+   contenham tags "Closes:" apontando para o seu e-mail ou para o ticket
+   mencionado.
+
+O que é importante ao corrigir regressões
+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+
+Você não precisa fazer nada de especial ao enviar correções para
+regressões; apenas lembre-se de fazer o que
+Documentation/process/submitting-patches.rst,
+:ref:`Documentation/process/5.Posting.rst <development_posting>` e
+Documentation/process/stable-kernel-rules.rst já explicam em mais
+detalhes:
+
+ * Aponte para todos os lugares onde o problema foi relatado usando tags
+    "Closes:" ::
+
+       Closes:
+       https://lore.kernel.org/r/30th.anniversary.repost@klaava.Helsinki.FI/
+       Closes: https://bugzilla.kernel.org/show_bug.cgi?id=1234567890
+
+   Se você estiver corrigindo apenas parte do problema, pode usar
+   "Link:" em vez disso, como descrito no primeiro documento mencionado
+   acima. No momento, o regzbot trata os dois de forma equivalente e
+   considera os relatos vinculados como resolvidos.
+
+ * Adicione uma tag "Fixes:" especificando o commit que causou a
+    regressão.
+
+ * Se o culpado foi mesclado em um ciclo de desenvolvimento anterior,
+    marque explicitamente a correção para backport usando a tag ``Cc:
+    stable@vger.kernel.org``.
+
+Tudo isso é esperado de você e importante quando se trata de regressão,
+pois essas tags têm grande valor para todos (inclusive você) que possam
+estar investigando o problema semanas, meses ou anos depois. Essas tags
+também são cruciais para ferramentas e scripts usados por outros
+desenvolvedores do kernel ou por distribuições Linux; uma dessas
+ferramentas é o regzbot, que depende fortemente das tags "Closes:" para
+associar relatos de regressão às mudanças que os resolvem.
+
+Expectativas e boas práticas para corrigir regressões
+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+
+Como desenvolvedor do kernel Linux, espera-se que você dê o seu melhor
+para evitar situações em que uma regressão causada por uma mudança
+recente sua deixe aos usuários apenas estas opções:
+
+ * Rodar um kernel com uma regressão que impacta o uso.
+
+ * Mudar para uma série de kernel mais antiga ou mais nova.
+
+ * Continuar rodando um kernel desatualizado e, portanto, potencialmente
+    inseguro, por mais de três semanas após a identificação do culpado
+    pela regressão. O ideal é que seja menos de duas. E deveria ser
+    questão de poucos dias, se o problema for grave ou afetar muitos
+    usuários -- seja de modo geral, seja em ambientes prevalentes.
+
+Como concretizar isso na prática depende de vários fatores. Use as
+regras gerais a seguir como guia.
+
+Em geral:
+
+ * Priorize o trabalho em regressões acima de qualquer outro trabalho no
+    kernel Linux, a menos que este último envolva um problema grave (por
+    exemplo, vulnerabilidade de segurança aguda, perda de dados,
+    hardware inutilizado, ...).
+
+ * Agilize a correção de regressões do mainline que recentemente
+    entraram em uma versão mainline, stable ou longterm de fato (seja
+    diretamente, seja via backport).
+
+ * Não considere as regressões do ciclo atual como algo que pode esperar
+    até o fim do ciclo, pois o problema pode desestimular ou impedir que
+    usuários e sistemas de CI testem o mainline agora ou de modo geral.
+
+ * Trabalhe com o cuidado necessário para evitar danos adicionais ou
+    maiores, mesmo que resolver o problema leve mais tempo do que o
+    descrito abaixo.
+
+Sobre prazos quando o culpado de uma regressão é conhecido:
+
+ * Procure levar uma correção ao mainline em dois ou três dias, se o
+    problema for grave ou incomodar muitos usuários -- seja de modo
+    geral, seja em condições prevalentes, como um ambiente de hardware
+    específico, uma distribuição ou uma série stable/longterm.
+
+ * Procure levar uma correção ao mainline até o domingo seguinte ao
+    próximo, se o culpado entrou em uma versão mainline, stable ou
+    longterm recente (seja diretamente, seja via backport); se o culpado
+    ficou conhecido no início da semana e é simples de resolver, tente
+    levar a correção ao mainline na mesma semana.
+
+ * Para outras regressões, procure levar as correções ao mainline antes
+    do último domingo dentro das próximas três semanas. Um ou dois
+    domingos depois é aceitável, se a regressão for algo com que as
+    pessoas consigam conviver facilmente por um tempo -- como uma
+    regressão leve de desempenho.
+
+ * É fortemente desaconselhado adiar correções de regressão para a
+    próxima janela de merge, exceto quando a correção for
+    extraordinariamente arriscada ou quando o culpado tiver sido levado
+    ao mainline há mais de um ano.
+
+Sobre procedimento:
+
+ * Sempre considere reverter o culpado, pois costuma ser a forma mais
+    rápida e menos perigosa de corrigir uma regressão. Não se preocupe
+    em levar ao mainline uma variante corrigida depois: isso deve ser
+    direto, já que a maior parte do código passou por revisão uma vez.
+
+ * Procure resolver qualquer regressão introduzida no mainline nos
+    últimos doze meses antes que o ciclo de desenvolvimento atual
+    termine: Linus quer que tais regressões sejam tratadas como as do
+    ciclo atual, a menos que a correção envolva riscos incomuns.
+
+ * Considere colocar Linus em CC nas discussões ou na revisão do patch,
+    se uma regressão parecer emaranhada. Faça o mesmo em casos precários
+    ou urgentes -- especialmente se o mantenedor do subsistema puder
+    estar indisponível. Coloque também a equipe stable em CC quando
+    souber que tal regressão entrou em uma versão mainline, stable ou
+    longterm.
+
+ * Para regressões urgentes, considere pedir a Linus que pegue a
+    correção diretamente da lista de discussão: ele não vê problema
+    nisso para correções sem controvérsia. O ideal, porém, é que tais
+    pedidos aconteçam em acordo com os mantenedores do subsistema ou
+    venham diretamente deles.
+
+ * Caso não tenha certeza se uma correção vale o risco de ser aplicada
+    poucos dias antes de uma nova versão mainline, envie a Linus um
+    e-mail com as listas e pessoas habituais em CC; nele, resuma a
+    situação e peça que ele considere pegar a correção diretamente da
+    lista. Ele então pode tomar a decisão e, quando necessário, até
+    adiar a versão. Tais pedidos, novamente, devem idealmente acontecer
+    em acordo com os mantenedores do subsistema ou vir diretamente
+    deles.
+
+Sobre kernels stable e longterm:
+
+ * Você é livre para deixar regressões para a equipe stable, se elas em
+    momento algum ocorreram no mainline ou já foram corrigidas lá.
+
+ * Se uma regressão entrou em uma versão mainline de fato nos últimos
+    doze meses, garanta marcar a correção com "Cc:
+    stable@vger.kernel.org", pois uma tag "Fixes:" sozinha não garante
+    um backport. Adicione a mesma tag caso saiba que o culpado foi
+    levado por backport para kernels stable ou longterm.
+
+ * Ao receber relatos sobre regressões em séries de kernel stable ou
+    longterm recentes, avalie ao menos brevemente se o problema pode
+    ocorrer também no mainline atual -- e, se isso parecer provável,
+    assuma o relato. Em caso de dúvida, peça ao autor que verifique o
+    mainline.
+
+ * Sempre que quiser resolver rapidamente uma regressão que recentemente
+    também entrou em uma versão mainline, stable ou longterm de fato,
+    corrija-a rapidamente em mainline; quando apropriado, envolva então
+    Linus para acelerar a correção (veja acima). Isso porque a equipe
+    stable normalmente não reverte nem corrige mudanças que causem os
+    mesmos problemas no mainline.
+
+ * Em caso de correções urgentes de regressão, você pode querer garantir
+    um backport célere enviando uma nota à equipe stable assim que a
+    correção for levada ao mainline; isso é especialmente recomendável
+    durante janelas de merge e logo depois delas, pois de outro modo a
+    correção pode parar no fim de uma fila enorme de patches.
+
+Sobre o fluxo de patches:
+
+ * Desenvolvedores, ao tentarem alcançar os prazos mencionados acima,
+    lembrem-se de considerar o tempo necessário para que as correções
+    sejam testadas, revisadas e mescladas por Linus, idealmente passando
+    ao menos brevemente pelo linux-next. Assim, se uma correção for
+    urgente, deixe isso óbvio para garantir que os outros a tratem
+    adequadamente.
+
+ * Revisores, pedimos gentilmente que auxiliem os desenvolvedores a
+    cumprir os prazos mencionados acima revisando as correções de
+    regressão em tempo hábil.
+
+ * Mantenedores de subsistema, vocês também são encorajados a agilizar o
+    tratamento de correções de regressão. Assim, avaliem se pular o
+    linux-next é uma opção para a correção em questão. Considerem também
+    enviar pull requests do git com mais frequência que o habitual
+    quando necessário. E procurem evitar segurar correções de regressão
+    durante os fins de semana -- especialmente quando a correção estiver
+    marcada para backport.
+
+
+Mais aspectos sobre regressões que os desenvolvedores devem conhecer
+---------------------------------------------------------------------
+
+
+Como lidar com mudanças em que há risco conhecido de regressão
+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+
+Avalie quão grande é o risco de regressões, por exemplo realizando uma
+busca de código em distribuições Linux e em forjas Git. Considere também
+pedir a outros desenvolvedores ou a projetos provavelmente afetados que
+avaliem ou até testem a mudança proposta; se surgirem problemas, talvez
+seja possível encontrar alguma solução aceitável para todos.
+
+Se ao final o risco de regressões parecer relativamente pequeno,
+prossiga com a mudança, mas informe todas as partes envolvidas sobre o
+risco. Assim, garanta que a descrição do seu patch torne esse aspecto
+óbvio. Depois que a mudança for mesclada, conte ao rastreador de
+regressões do kernel Linux e à lista de discussão de regressões sobre o
+risco, para que todos tenham a mudança no radar caso relatos comecem a
+aparecer. Dependendo do risco, você também pode querer pedir ao
+mantenedor do subsistema que mencione o assunto no pull request dele
+para o mainline.
+
+O que mais há para saber sobre regressões?
+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+
+Confira Documentation/admin-guide/reporting-regressions.rst; ele cobre
+vários outros aspectos que você pode querer conhecer:
+
+ * o propósito da regra "sem regressões"
+
+ * quais problemas de fato se qualificam como regressão
+
+ * quem é responsável por encontrar a causa raiz de uma regressão
+
+ * como lidar com situações complicadas, por exemplo quando uma
+    regressão é causada por uma correção de segurança ou quando corrigir
+    uma regressão pode causar outra
+
+A quem pedir conselho quando se trata de regressões
+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+
+Envie um e-mail para a lista de discussão de regressões
+(regressions@lists.linux.dev) com o rastreador de regressões do kernel
+Linux (regressions@leemhuis.info) em CC; se o assunto puder ser tratado
+melhor em particular, sinta-se à vontade para omitir a lista.
+
+
+Mais sobre o acompanhamento de regressões e o regzbot
+------------------------------------------------------
+
+
+Por que o kernel Linux tem um rastreador de regressões e por que o
+regzbot é usado?
+~~~~~~~~~~~~~~~~
+
+Regras como "sem regressões" precisam de alguém que garanta que sejam
+seguidas, caso contrário são quebradas por acidente ou de propósito. A
+história tem mostrado que isso é verdadeiro também para o kernel Linux.
+É por isso que Thorsten Leemhuis se ofereceu para ficar de olho nas
+coisas como rastreador de regressões do kernel Linux, sendo
+ocasionalmente ajudado por outras pessoas. Nenhum deles é pago para
+fazer isso, e é por isso que o acompanhamento de regressões é feito na
+base do melhor esforço.
+
+Tentativas anteriores de acompanhar regressões manualmente mostraram que
+é um trabalho exaustivo e frustrante, motivo pelo qual foram abandonadas
+depois de um tempo. Para evitar que isso acontecesse de novo, Thorsten
+desenvolveu o regzbot para facilitar o trabalho, com o objetivo de longo
+prazo de automatizar o acompanhamento de regressões o máximo possível
+para todos os envolvidos.
+
+Como funciona o acompanhamento de regressões com o regzbot?
+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+
+O robô observa as respostas aos relatos de regressões acompanhadas. Além
+disso, ele procura patches publicados ou commitados que referenciem tais
+relatos com tags "Closes:"; respostas a esses envios de patch também são
+acompanhadas. Combinados, esses dados oferecem boa visão do estado atual
+do processo de correção.
+
+O regzbot procura fazer o seu trabalho com a menor sobrecarga possível
+tanto para quem relata quanto para os desenvolvedores. Na verdade,
+apenas quem relata recebe um dever extra: é preciso informar ao regzbot
+sobre o relato de regressão usando o comando ``#regzbot introduced``
+descrito acima; se a pessoa não fizer isso, alguém pode cuidar disso
+usando ``#regzbot ^introduced``.
+
+Para os desenvolvedores normalmente não há trabalho extra envolvido;
+eles só precisam garantir que fazem algo esperado muito antes de o
+regzbot existir: adicionar à descrição do patch links para todos os
+relatos sobre o problema corrigido.
+
+Eu preciso usar o regzbot?
+~~~~~~~~~~~~~~~~~~~~~~~~~~
+
+É do interesse de todos que você use, pois mantenedores do kernel como
+Linus Torvalds se apoiam em parte no acompanhamento do regzbot em seu
+trabalho -- por exemplo, ao decidir lançar uma nova versão ou estender a
+fase de desenvolvimento. Para isso, eles precisam estar cientes de todas
+as regressões não corrigidas; para tanto, sabe-se que Linus examina os
+relatórios semanais enviados pelo regzbot.
+
+Preciso contar ao regzbot sobre toda regressão com que eu esbarrar?
+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+
+O ideal é que sim: somos todos humanos e esquecemos facilmente de
+problemas quando algo mais importante surge de repente -- por exemplo,
+um problema maior no kernel Linux ou algo na vida real que nos mantenha
+longe do teclado por um tempo. Assim, é melhor contar ao regzbot sobre
+toda regressão, exceto quando você escreve uma correção imediatamente e
+a commita em uma árvore regularmente mesclada na série de kernel
+afetada.
+
+Como ver quais regressões o regzbot acompanha no momento?
+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+
+Consulte a `interface web do regzbot
+<https://linux-regtracking.leemhuis.info/regzbot/>`_ para as informações
+mais recentes; alternativamente, `procure o relatório de regressões mais
+recente
+<https://lore.kernel.org/lkml/?q=%22Linux+regressions+report%22+f%3Aregzbot>`_,
+que o regzbot normalmente envia uma vez por semana, no domingo à noite
+(UTC), algumas horas antes de Linus publicar novas versões (ou
+pré-versões).
+
+Quais lugares o regzbot monitora?
+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+
+O regzbot observa as listas de discussão mais importantes do Linux, bem
+como os repositórios git do linux-next, do mainline e das séries
+stable/longterm.
+
+Que tipo de problema deve ser acompanhado pelo regzbot?
+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+
+O robô serve para acompanhar regressões; portanto, não envolva o regzbot
+em problemas comuns. Mas não há problema, para o rastreador de
+regressões do kernel Linux, se você usar o regzbot para acompanhar
+problemas graves, como relatos de travamentos, dados corrompidos ou
+erros internos (Panic, Oops, BUG(), warning, ...).
+
+Posso adicionar ao acompanhamento do regzbot regressões encontradas por
+sistemas de CI?
+~~~~~~~~~~~~~~~
+
+Fique à vontade para fazê-lo, se a regressão em questão provavelmente
+tiver impacto em casos de uso práticos e, assim, puder ser notada por
+usuários; portanto, não envolva o regzbot em regressões teóricas com
+pouca chance de se manifestarem no uso real.
+
+Como interagir com o regzbot?
+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+
+Usando um 'comando do regzbot' em uma resposta direta ou indireta ao
+e-mail com o relato de regressão. Esses comandos precisam estar em seu
+próprio parágrafo (ou seja: precisam ser separados do restante do e-mail
+por linhas em branco).
+
+Um desses comandos é ``#regzbot introduced: <versão ou commit>``, que
+faz o regzbot considerar o seu e-mail como um relato de regressão
+adicionado ao acompanhamento, como já descrito acima; ``#regzbot
+^introduced: <versão ou commit>`` é outro desses comandos, que faz o
+regzbot considerar o e-mail pai como um relato de uma regressão que ele
+passa a acompanhar.
+
+Depois que um desses dois comandos tiver sido usado, outros comandos do
+regzbot podem ser usados em respostas diretas ou indiretas ao relato.
+Você pode escrevê-los abaixo de um dos comandos `introduced` ou em
+respostas ao e-mail que usou um deles, ou que por sua vez seja resposta
+a esse e-mail:
+
+ * Definir ou atualizar o título::
+
+       #regzbot title: foo
+
+ * Monitorar uma discussão ou um ticket em bugzilla.kernel.org onde
+    aspectos adicionais do problema ou de uma correção são discutidos --
+    por exemplo, a publicação de um patch que corrige a regressão::
+
+       #regzbot monitor:
+       https://lore.kernel.org/all/30th.anniversary.repost@klaava.Helsinki.FI/
+
+   O monitoramento funciona apenas para lore.kernel.org e
+   bugzilla.kernel.org; o regzbot considerará todas as mensagens naquele
+   encadeamento ou ticket como relacionadas ao processo de correção.
+
+ * Apontar para um lugar com mais detalhes de interesse, como uma
+    mensagem em lista de discussão ou um ticket em um rastreador de bugs
+    que sejam levemente relacionados, mas sobre outro assunto::
+
+       #regzbot link:
+       https://bugzilla.kernel.org/show_bug.cgi?id=123456789
+
+ * Marcar uma regressão como corrigida por um commit que está indo para
+    o upstream ou já foi aplicado::
+
+       #regzbot fix: 1f2e3d4c5d
+
+ * Marcar uma regressão como duplicada de outra já acompanhada pelo regzbot::
+
+       #regzbot dup-of: https://lore.kernel.org/all/30th.anniversary.repost@klaava.Helsinki.FI/
+
+ * Marcar uma regressão como inválida::
+
+       #regzbot invalid: wasn't a regression, problem has always existed
+
+Há mais a dizer sobre o regzbot e seus comandos?
+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+
+Informações mais detalhadas e atualizadas sobre o robô de acompanhamento
+de regressões do kernel Linux podem ser encontradas na sua `página do
+projeto <https://gitlab.com/knurd42/regzbot>`_, que entre outras coisas
+contém um `guia de primeiros passos
+<https://gitlab.com/knurd42/regzbot/-/blob/main/docs/getting_started.md>`_
+e `documentação de referência
+<https://gitlab.com/knurd42/regzbot/-/blob/main/docs/reference.md>`_,
+ambos cobrindo mais detalhes do que a seção acima.
+
+Citações de Linus sobre regressão ---------------------------------
+
+As declarações a seguir, de Linus Torvalds, oferecem alguma compreensão
+sobre a regra "sem regressões" do Linux e sobre como ele espera que as
+regressões sejam tratadas:
+
+Sobre a rapidez com que as regressões devem ser corrigidas
+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+
+* De `2026-01-22 <https://lore.kernel.org/all/CAHk-=wheQNiW_WtHGO7bKkT7Uib-p+ai2JP9M+z+FYcZ6CAxYA@mail.gmail.com/>`_::
+
+    Mas um usuário reclamando deve basicamente resultar em uma correção
+    imediata - possivelmente um "reverter e repensar".
+
+  Com um esclarecimento posterior, de `2026-01-28 <https://lore.kernel.org/all/CAHk-%3Dwi86AosXs66-yi54%2BmpQjPu0upxB8ZAfG%2BLsMyJmcuMSA@mail.gmail.com/>`_::
+
+    Vale notar também que "imediata" obviamente não significa "neste
+    *segundo* em que o problema foi relatado".
+
+    Mas se for uma regressão com um commit conhecido que a causou, penso
+    que a regra geral deve ser "dentro de uma semana", de preferência
+    antes do próximo rc.
+
+* De `2023-04-21 <https://lore.kernel.org/all/CAHk-=wgD98pmSK3ZyHk_d9kZ2bhgN6DuNZMAJaV0WTtbkf=RDw@mail.gmail.com/>`_::
+
+    Commits sabidamente quebrados ou
+     (a) recebem uma correção em tempo hábil que não traga outras questões
+    ou
+     (b) são revertidos
+
+* De `2021-09-20(2) <https://lore.kernel.org/all/CAHk-=wgOvmtRw1TNbMC1rn5YqyTKyn0hz+sc4k0DGNn++u9aYw@mail.gmail.com/>`_::
+
+    [...] a revisão não deveria barrar regressões relatadas de código
+    existente. Isso é apenas _teste_ básico - ou a correção deve ser
+    aplicada, ou - se a correção for invasiva ou feia demais - a fonte
+    problemática da regressão deve ser revertida.
+
+    Revisão deveria ser sobre código novo, não deveria barrar "existe um
+    relato de bug, aqui está a correção óbvia".
+* De `2023-05-08 <https://lore.kernel.org/all/CAHk-=wgzU8_dGn0Yg+DyX7ammTkDUCyEJ4C=NvnHRhxKWC7Wpw@mail.gmail.com/>`_::
+
+    Se algo nem sequer compila, deve ser corrigido o quanto antes, sim.
+
+Como reversões ajudam a evitar o esgotamento de mantenedores
+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+
+* De `2026-01-28 <https://lore.kernel.org/all/CAHk-%3Dwi86AosXs66-yi54%2BmpQjPu0upxB8ZAfG%2BLsMyJmcuMSA@mail.gmail.com/>`_::
+
+    > Então como eu/nós podemos fazer "correções imediatas" acontecerem com
+    > mais frequência sem contribuir para o esgotamento de mantenedores?
+
+    [...] o modelo de "reverter e repensar" [...] costuma ser uma boa
+    ideia em geral [...]
+
+    Justamente para que os mantenedores não fiquem estressados por terem um
+    relato de problema pendente sobre o qual as pessoas insistem em cobrar.
+
+    Penso que às vezes as pessoas ficam um pouco apegadas demais às
+    mudanças que fizeram, e reverter é visto como "drástico demais", mas
+    penso que costuma ser a solução rápida e fácil quando não há alguma
+    resposta óbvia a um relato de regressão.
+
+Sobre correções quando o último -rc ou versão está próximo
+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+
+* De `2026-02-01 <https://lore.kernel.org/all/CAHk-%3DwhXTw1oPsa%2BTLuY1Rc9D1OAiPVOdR_-R2xG45kwDObKdA@mail.gmail.com/>`_::
+
+    Então penso que prefiro vê-las entrar no rc8 (mais tarde hoje) e ter
+    uma semana de testes na minha árvore e serem revertidas se causarem
+    problemas, do que vê-las entrar depois do rc8 e então causarem
+    problemas na versão 6.19.
+
+* De `2023-04-20 <https://lore.kernel.org/all/CAHk-=wis_qQy4oDNynNKi5b7Qhosmxtoj1jxo5wmB6SRUwQUBQ@mail.gmail.com/>`_::
+
+    Mas algo como isto, em que a regressão estava na versão anterior e é
+    apenas uma correção clara sem sutileza semântica, considero apenas uma
+    regressão comum que deve ser acelerada - em parte para chegar ao stable,
+    e em parte para evitar ter de colocar a correção em _outro_ kernel
+    stable.
+
+Sobre enviar merge requests com apenas uma correção
+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+
+* De `2024-04-24 <https://lore.kernel.org/all/CAHk-=wjy_ph9URuFt-pq+2AJ__p7gFDx=yzVSCsx16xAYvNw9g@mail.gmail.com/>`_::
+
+    Se o problema é apenas não haver mais nada acontecendo, penso que as
+    pessoas deveriam simplesmente me apontar o patch e dizer "pode aplicar
+    esta correção única?"
+
+* De `2023-04-20 <https://lore.kernel.org/all/CAHk-=wis_qQy4oDNynNKi5b7Qhosmxtoj1jxo5wmB6SRUwQUBQ@mail.gmail.com/>`_::
+
+    Estou sempre aberto a correções diretas quando não há controvérsia
+    sobre a correção. Sem problema. Continuo lidando de bom grado com patches
+    individuais.
+
+Sobre apontar relatos de bug com as tags Link:/Closes:
+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+
+* De `2025-07-29(1) <https://lore.kernel.org/all/CAHk-=wj2kJRPWx8B09AAtzj+_g+T6UBX11TP0ebs1WJdTtv=WQ@mail.gmail.com/>`_::
+
+    [...] reverter assim, seria realmente bom linkar os problemas, para que
+    quando as pessoas tentarem reabilitar, tenham o histórico de por que não
+    funcionou na primeira vez.
+
+* De `2022-05-08 <https://lore.kernel.org/all/CAHk-=wjMmSZzMJ3Xnskdg4+GGz=5p5p+GSYyFBTh0f-DgvdBWg@mail.gmail.com/>`_::
+
+    Então tenho de reclamar mais uma vez [...]
+
+    [...] Não há link para o problema real que o patch corrige.
+
+* De `2022-06-22 <https://lore.kernel.org/all/CAHk-=wjxzafG-=J8oT30s7upn4RhBs6TX-uVFZ5rME+L5_DoJA@mail.gmail.com/>`_::
+
+    Veja, *aquele* link [para o relato] teria sido útil no commit.
+
+Sobre por que a regra "sem regressões" existe
+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+
+* De `2026-01-22 <https://lore.kernel.org/all/CAHk-=wheQNiW_WtHGO7bKkT7Uib-p+ai2JP9M+z+FYcZ6CAxYA@mail.gmail.com/>`_::
+
+    Mas a regra básica é: seja tão bom em compatibilidade reversa que os
+    usuários nunca precisem se preocupar em atualizar. Eles devem
+    absolutamente se sentir confiantes de que qualquer problema relatado ao
+    kernel será resolvido ou terá uma solução fácil apropriada para *eles*
+    (ou seja, não se espera que um usuário não técnico consiga fazer muita
+    coisa).
+
+    Porque a última coisa que queremos é gente evitando testar kernels
+    novos.
+
+* De `2024-05-28 <https://lore.kernel.org/all/CAHk-=wgtb7y-bEh7tPDvDWru7ZKQ8-KMjZ53Tsk37zsPPdwXbA@mail.gmail.com/>`_::
+
+    Introduzi essa regra de "sem regressões" há algo como duas décadas,
+    porque as pessoas precisam poder atualizar o seu kernel sem medo de que
+    algo em que confiavam pare de funcionar de repente.
+
+* De `2018-08-03 <https://lore.kernel.org/all/CA+55aFwWZX=CXmWDTkDGb36kf12XmTehmQjbiMPCqCRG2hi9kw@mail.gmail.com/>`_::
+
+    O ponto central de "não causamos regressões" é que as pessoas possam
+    atualizar o kernel e nunca precisarem se preocupar com isso.
+
+    [...]
+
+    Porque a única coisa que importa É O USUÁRIO.
+
+* De `2017-10-26(1) <https://lore.kernel.org/lkml/CA+55aFxW7NMAMvYhkvz1UPbUTUJewRt6Yb51QAx5RtrWOwjebg@mail.gmail.com/>`_::
+
+    Se o kernel funcionava para você, a regra é que ele continua
+    funcionando para você.
+
+    [...]
+
+    As pessoas deveriam basicamente sempre sentir que podem atualizar o seu
+    kernel e simplesmente não precisar se preocupar com isso.
+
+    Eu me recuso a introduzir limitações do tipo "você só pode atualizar o
+    kernel se também atualizar aquele outro programa". Se o kernel
+    funcionava para você, a regra é que ele continua funcionando para você.
+
+Sobre exceções à regra "sem regressões"
+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+
+* De `2026-01-22 <https://lore.kernel.org/all/CAHk-=wheQNiW_WtHGO7bKkT7Uib-p+ai2JP9M+z+FYcZ6CAxYA@mail.gmail.com/>`_::
+
+    Há _muito_ poucas exceções a essa regra, sendo a principal "o
+    problema era uma questão de segurança fundamental, enorme e gritante, e
+    nós *tivemos* de fazer aquela mudança, e não conseguimos sequer fazer o
+    seu caso de uso limitado continuar funcionando".
+
+    A outra exceção é "o problema foi relatado anos depois de ter sido
+    introduzido, e agora a maioria das pessoas depende do novo
+    comportamento".
+
+    [...]
+
+    Agora, se forem um ou dois usuários e você conseguir simplesmente fazer
+    com que recompilem,
+    isso é uma coisa. Hardware de nicho e casos de uso estranhos às vezes
+    podem ser resolvidos assim, e regressões às vezes podem ser corrigidas
+    orientando cada pessoa que relata, se ela estiver disposta e puder mudar
+    o seu fluxo de trabalho.
+
+* De `2023-04-20 <https://lore.kernel.org/all/CAHk-=wis_qQy4oDNynNKi5b7Qhosmxtoj1jxo5wmB6SRUwQUBQ@mail.gmail.com/>`_::
+
+    E sim, considero "regressão em uma versão anterior" uma regressão que
+    precisa de correção.
+
+    Obviamente há um limite de tempo: se aquela "regressão em uma versão
+    anterior" foi há um ano ou mais, e simplesmente levou uma eternidade
+    para as pessoas notarem, e tinha mudanças semânticas que agora
+    significam que corrigir a regressão poderia causar uma _nova_
+    regressão, então isso pode me levar a dizer "Ah, agora a nova semântica
+    é com o que temos de conviver".
+
+* De `2017-10-26(2) <https://lore.kernel.org/lkml/CA+55aFxW7NMAMvYhkvz1UPbUTUJewRt6Yb51QAx5RtrWOwjebg@mail.gmail.com/>`_::
+
+    Houve exceções, mas são raras, e geralmente têm algum motivo maior e
+    fundamental para terem acontecido, basicamente totalmente inevitável, e
+    as pessoas _tentaram_muito_ evitá-las. Talvez não consigamos mais
+    suportar o hardware, na prática, depois de décadas de idade e de
+    ninguém mais usá-lo com kernels modernos. Talvez haja um problema de
+    segurança sério em como fizemos as coisas, e as pessoas de fato
+    dependiam daquele modelo fundamentalmente quebrado. Talvez tenha havido
+    alguma outra quebra fundamental que simplesmente _tinha_ de ter um dia
+    de virada por razões muito centrais e fundamentais.
+
+Sobre atualizar o espaço de usuário para resolver regressões
+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+
+* De `2018-08-03 <https://lore.kernel.org/all/CA+55aFwWZX=CXmWDTkDGb36kf12XmTehmQjbiMPCqCRG2hi9kw@mail.gmail.com/>`_::
+
+    E caramba, nós atualizamos o kernel O TEMPO TODO sem atualizar nenhum
+    outro programa. Isso é absolutamente necessário, porque flag days
+    e dependências são terrivelmente ruins.
+
+    E também é necessário simplesmente porque eu, como desenvolvedor do
+    kernel, não atualizo ferramentas aleatórias das quais nem me importo
+    enquanto desenvolvo o kernel, e quero que qualquer um dos meus usuários
+    se sinta seguro fazendo o mesmo.
+
+* De `2017-10-26(3) <https://lore.kernel.org/lkml/CA+55aFxW7NMAMvYhkvz1UPbUTUJewRt6Yb51QAx5RtrWOwjebg@mail.gmail.com/>`_::
+
+    Mas se algo de fato quebrar, então a mudança precisa ser corrigida ou
+    revertida. E ela é corrigida no *kernel*. Não dizendo "bem, corrija o
+    seu espaço de usuário então". Foi uma mudança no kernel que expôs o
+    problema, precisa ser o kernel que corrija isso, porque temos um modelo
+    de "atualizar no lugar". Não temos um "atualizar com espaço de usuário
+    novo".
+
+    E eu vou seriamente me recusar a aceitar código de pessoas que não
+    entendem e não honram esta regra muito simples.
+
+    Esta regra também não vai mudar.
+
+    E sim, eu percebo que o kernel é "especial" nesse aspecto. Tenho
+    orgulho disso.
+
+* De `2017-10-26(4) <https://lore.kernel.org/all/CA+55aFwiiQYJ+YoLKCXjN_beDVfu38mg=Ggg5LFOcqHE8Qi7Zw@mail.gmail.com/>`_::
+
+    Se você quebra configurações de espaço de usuário existentes, ISSO É
+    UMA REGRESSÃO.
+
+    Não é aceitável dizer "mas nós vamos corrigir a configuração do espaço
+    de usuário".
+
+    Sério. NÃO É ACEITÁVEL.
+
+O que qualifica como interface: ABI, API e documentação
+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+
+* De `2026-01-20 <https://lore.kernel.org/all/CAHk-=wga8Qu0-OSE9VZbviq9GuqwhPhLUXeAt-S7_9+fMCLkKg@mail.gmail.com/>`_::
+
+    Então eu absolutamente detesto toda a noção de "mudanças de ABI". É um
+    conceito sem sentido, e eu o odeio com paixão, [...]
+
+    A regra do Linux para regressões baseia-se basicamente na questão
+    filosófica de "se uma árvore cai na floresta e ninguém está por perto
+    para ouvir, ela faz som?".
+
+    Então a única coisa que importa é se algo quebra comportamento
+    *consciente* do usuário.
+
+    E quando isso acontece, a distinção entre "correção de bug" e "nova
+    funcionalidade" e "mudança de ABI" não importa nem um pouco, e a
+    mudança precisa ser feita de outra forma.
+
+    [...]
+
+    Eu só queria apontar que o argumento sobre ser ou não uma mudança de
+    ABI é irrelevante. Se ocorrer de algum programa - não um script de
+    teste, mas algo relevante para as expectativas conscientes do usuário -
+    depender do comportamento antigo e quebrado, então isso precisa ser
+    feito de outra maneira.
+
+* De `2026-02-13 <https://lore.kernel.org/all/CAHk-=whY-N8kjm8kiFUV5Ei-8AuYw--EPGD-AR3Pd+5GTx2sAQ@mail.gmail.com/>`_::
+
+    > [...] isto não deveria se enquadrar na regra de não quebrar o espaço
+    > de usuário [...]
+
+    Note que a regra é sobre quebrar *usuários*, não quebrar o espaço de
+    usuário em si. [...]
+
+    Se alguma configuração de usuário quebra, as coisas precisam ser
+    corrigidas.
+
+    [...] mas quero deixar muito claro que não há desculpas quanto a
+    "aplicações de espaço de usuário".
+
+* De `2021-09-20(4) <https://lore.kernel.org/all/CAHk-=wi7DB2SJ-wngVvsJ7Ak2cM556Q8437sOXo4EJt2BWPdEg@mail.gmail.com/>`_::
+
+    [...] uma regressão é um pouco como o gato de Schrödinger - se ninguém
+    está por perto para notá-la e ela de fato não afeta nenhuma carga de
+    trabalho real, então você pode tratar a regressão como se não
+    existisse.
+
+* De `2020-05-21 <https://lore.kernel.org/all/CAHk-=wiVi7mSrsMP=fLXQrXK_UimybW=ziLOwSzFTtoXUacWVQ@mail.gmail.com/>`_::
+
+    As regras sobre regressões nunca foram sobre qualquer tipo de
+    comportamento documentado, ou sobre onde o código vive.
+
+    As regras sobre regressões são sempre sobre "quebrar o fluxo de
+    trabalho do usuário".
+
+    Os usuários são literalmente a _única_ coisa que importa.
+
+* De `2019-09-15 <https://lore.kernel.org/lkml/CAHk-=wiP4K8DRJWsCo=20hn_6054xBamGKF2kPgUzpB5aMaofA@mail.gmail.com/>`_::
+
+    Uma reversão _particularmente_ de última hora é o commit mais ao topo
+    (ignorando a mudança de versão em si) feito pouco antes do lançamento,
+    e, embora seja muito chata, é talvez também instrutiva.
+
+    O que é instrutivo nela é que eu reverti um commit que não tinha bug
+    algum. De fato, ele fazia exatamente o que se propunha a fazer, e fazia
+    muito bem. Tão bem que os padrões de E/S muito melhores que ele causou
+    acabaram revelando uma regressão visível ao usuário, devido a um bug
+    real em uma área completamente não relacionada.
+
+    Os detalhes reais dessa regressão, porém, não são o motivo pelo qual
+    aponto aquela reversão como instrutiva. É mais que ela é um exemplo
+    instrutivo do que conta como regressão e do que significa a regra do
+    kernel de "sem regressões".
+
+    [...] O commit revertido não mudou nenhuma API e não introduziu nenhum
+    bug novo. Mas acabou expondo outro problema e, assim, fez uma atualização
+    de kernel falhar para um usuário. Então foi revertido.
+
+    O ponto aqui é que revertemos com base no _comportamento_ relatado pelo
+    usuário, não com base em algum conceito de "isso muda a ABI" ou "isso
+    causou um bug". O problema já existia de fato, e simplesmente não tinha
+    disparado antes. [...]
+
+    Conclusão de tudo isso: não se trata de saber se você muda a ABI entre
+    kernel e espaço de usuário, ou se corrige um bug, ou se o código antigo
+    "nunca deveria ter funcionado". Trata-se de saber se algo quebra o
+    fluxo de trabalho dos usuários existentes.
+
+* De `2017-11-05 <https://lore.kernel.org/all/CA+55aFzUvbGjD8nQ-+3oiMBx14c_6zOj2n7KLN3UsJ-qsd4Dcw@mail.gmail.com/>`_::
+
+    E a nossa regra de regressão nunca foi "o comportamento não muda".
+    Isso significaria que nunca poderíamos fazer mudança alguma.
+
+* De `2020-05-21 <https://lore.kernel.org/all/CAHk-=wiVi7mSrsMP=fLXQrXK_UimybW=ziLOwSzFTtoXUacWVQ@mail.gmail.com/>`_::
+
+    Nenhuma quantidade de "você não deveria ter usado isso" ou "aquele
+    comportamento era indefinido, a culpa é sua por seu aplicativo ter
+    quebrado" ou "aquilo funcionava só por causa de um bug do kernel" é
+    minimamente relevante.
+
+* De `2021-05-21 <https://lore.kernel.org/all/CAHk-=wiVi7mSrsMP=fLXQrXK_UimybW=ziLOwSzFTtoXUacWVQ@mail.gmail.com/>`_::
+
+    Mas não, "estava documentado como quebrado" (seja porque o código
+    estava em staging, seja porque a página de manual dizia outra coisa) é
+    irrelevante. Se o código de staging é tão útil que as pessoas acabam
+    usando, isso significa que ele é basicamente código normal do kernel com
+    uma tag dizendo "por favor, limpe isto".
+
+    [...]
+
+    O outro lado da moeda é que as pessoas que falam em "estabilidade de
+    API" estão totalmente erradas. APIs também não importam. Você pode fazer
+    qualquer mudança em uma API que quiser - desde que ninguém note.
+
+    De novo, a regra de regressão não é sobre documentação, não é sobre
+    APIs e não é sobre a fase da lua.
+
+* De `2012-07-06 <https://lore.kernel.org/all/CA+55aFwnLJ+0sjx92EGREGTWOx84wwKaraSzpTNJwPVV8edw8g@mail.gmail.com/>`_::
+
+    > Agora isso me fez perguntar se o Debian _unstable_ de fato se
+    > qualifica como espaço de usuário de distribuição padrão.
+
+    Ah, se o kernel quebra algum espaço de usuário padrão, isso conta.
+    Muitíssimas pessoas rodam Debian unstable
+
+* De `2011-05-06 <https://lore.kernel.org/all/BANLkTi=KVXjKR82sqsz4gwjr+E0vtqCmvA@mail.gmail.com/>`_::
+
+    Claramente NÃO é um tracepoint interno. Por definição. Ele está sendo
+    usado pelo powertop.
+
+Sobre regressões notadas por usuários ou por suítes de teste/CI
+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+
+* De `2026-01-22 <https://lore.kernel.org/all/CAHk-=wheQNiW_WtHGO7bKkT7Uib-p+ai2JP9M+z+FYcZ6CAxYA@mail.gmail.com/>`_::
+
+    Usuários reclamando é a única linha real no fim das contas.
+
+    [...] uma suíte de teste reclamando é então frequentemente uma
+    indicação *muito* boa de que talvez os usuários esbarrem em algum
+    problema, e problemas de suíte de teste devem ser levados muito a sério
+    [...]
+
+    Mas um erro de suíte de teste não é necessariamente onde se deve traçar
+    a linha - é um grande sinal de alerta [...]
+
+* De `2024-29-01 <https://lore.kernel.org/all/CAHk-=wg8BrZEzjJ5kUyZzHPZmFqH6ooMN1gRBCofxxCfucgjaw@mail.gmail.com/>`_::
+
+    A regra "sem regressões" não é sobre um "se eu fizer isto, o
+    comportamento muda" inventado.
+
+    A regra "sem regressões" é sobre *usuários*.
+
+    Se você tem um usuário real que vem fazendo coisas insanas, e nós
+    mudamos algo, e agora a coisa insana não funciona mais, nesse ponto é
+    uma regressão, e nós vamos suspirar, dizer "usuários são insanos" e
+    ter de corrigir.
+
+    Mas se você tem algum teste aleatório que agora se comporta de modo
+    diferente, não é uma regressão. É um sinal de *alerta*, claro: testes
+    são úteis.
+
+Sobre aceitar quando uma regressão ocorreu
+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+
+* De `2026-01-22 <https://lore.kernel.org/all/CAHk-=wheQNiW_WtHGO7bKkT7Uib-p+ai2JP9M+z+FYcZ6CAxYA@mail.gmail.com/>`_::
+
+    Mas começar a discutir com usuários que relatam mudanças quebradas é
+    basicamente a linha final para mim. Tenho algumas pessoas na minha lista
+    de bloqueio de spam com as quais me recuso a ter qualquer coisa a ver, e
+    em geral foi exatamente por isso.
+
+    Note que não é sobre cometer erros e _causar_ a regressão. Isso é
+    normal. Isso é desenvolvimento. Mas discutir sobre isso é proibido.
+
+* De `2024-06-23 <https://lore.kernel.org/all/CAHk-=wi_KMO_rJ6OCr8mAWBRg-irziM=T9wxGC+J1VVoQb39gw@mail.gmail.com/>`_::
+
+    Nós não introduzimos regressões e depois culpamos os outros.
+
+    Há uma regra muito clara no desenvolvimento do kernel: coisas que
+    quebram outras coisas NÃO SÃO CORREÇÕES.
+
+    NUNCA.
+
+    Elas são revertidas, ou a coisa que quebraram é corrigida.
+
+* De `2021-06-05 <https://lore.kernel.org/all/CAHk-=wiUVqHN76YUwhkjZzwTdjMMJf_zN4+u7vEJjmEGh3recw@mail.gmail.com/>`_::
+
+    NÃO HÁ ARGUMENTOS VÁLIDOS PARA REGRESSÕES.
+
+    Honestamente, as pessoas de segurança precisam entender que "não
+    funcionar" não é um caso de sucesso da segurança. É um caso de falha.
+
+    Sim, "não funcionar" pode ser seguro. Mas segurança, nesse caso, é
+    *inútil*.
+
+* De `2017-10-26(5) <https://lore.kernel.org/lkml/CA+55aFwiiQYJ+YoLKCXjN_beDVfu38mg=Ggg5LFOcqHE8Qi7Zw@mail.gmail.com/>`_::
+
+    [...] quando regressões *de fato* ocorrem, nós as admitimos e as
+    corrigimos, em vez de culpar o espaço de usuário.
+
+    O fato de você aparentemente estar negando a regressão há três semanas
+    significa que eu vou reverter, e vou parar de aceitar pull requests do AppArmor até que as pessoas envolvidas entendam como o desenvolvimento do
+    kernel é feito.
+
+Sobre idas e vindas
+~~~~~~~~~~~~~~~~~~~
+
+* De `2024-05-28 <https://lore.kernel.org/all/CAHk-=wgtb7y-bEh7tPDvDWru7ZKQ8-KMjZ53Tsk37zsPPdwXbA@mail.gmail.com/>`_::
+
+    A regra "sem regressões" é que não introduzimos bugs NOVOS.
+
+    Ela surgiu *literalmente* porque tínhamos uma dança sem fim de
+    "corrigir dois bugs, introduzir um novo", e isso então resultava em um
+    sistema em que você NÃO PODE CONFIAR.
+
+* De `2021-09-20(1) <https://lore.kernel.org/all/CAHk-=wi7DB2SJ-wngVvsJ7Ak2cM556Q8437sOXo4EJt2BWPdEg@mail.gmail.com/>`_::
+
+    E o que torna as regressões especiais é que, na época em que eu não era
+    tão rígido com essas coisas, acabávamos em "situações de gangorra" sem
+    fim, em que alguém corrigia algo, isso quebrava outra coisa, então essa
+    outra coisa quebrava, e nunca se convergia de fato para nada confiável.
+
+* De `2015-08-13 <https://lore.kernel.org/all/CA+55aFxk8-BsiKwr_S-c+4G6wihKPQVMLE34H9wOZpeua6W9+Q@mail.gmail.com/>`_::
+
+    A política estrita de sem regressões começou, na verdade, principalmente
+    em relação a problemas de suspender/retomar, em que o vai e vem de
+    "corrigir uma máquina, quebrar outra" causava problemas sem fim, e
+    significava que não necessariamente fazíamos progresso algum, apenas
+    movendo um problema de lugar.
+
+Sobre mudanças com risco de causar regressões
+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+
+* De `2023-06-02 <https://lore.kernel.org/all/CAHk-=wgyAGUMHmQM-5Eb556z5xiHZB7cF05qjrtUH4F7P-1rSA@mail.gmail.com/>`_::
+
+    Então o que penso que você deveria fazer é corrigir o bug direito, com
+    um patch limpo e sem gambiarras malucas. Isso é algo que podemos então
+    aplicar e testar. Sabendo o tempo todo que "é, isto é uma mudança
+    visível, pode ser que tenhamos de revertê-la".
+
+    Se então alguma carga *real* acabar mostrando uma regressão, podemos
+    simplesmente estar ferrados. Nosso comportamento atual pode ter bugs,
+    mas temos a regra de que, uma vez que o espaço de usuário dependa de bugs
+    do kernel, eles se tornam funcionalidades basicamente por definição, por
+    mais que possamos não gostar disso.
+
+Sobre soluções de contorno no kernel para evitar regressões
+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+
+* De `2017-10-26(6) <https://lore.kernel.org/lkml/CA+55aFxW7NMAMvYhkvz1UPbUTUJewRt6Yb51QAx5RtrWOwjebg@mail.gmail.com/>`_::
+
+    Mudanças de comportamento acontecem, e talvez não suportemos mais
+    alguma funcionalidade. Há vários campos em /proc/<pid>/stat que são
+    impressos como zeros, simplesmente porque eles nem *existem* mais no
+    kernel, ou porque mostrá-los foi um erro (tipicamente um vazamento de
+    informação). Mas os números foram substituídos por zeros, para que o
+    código que analisava os campos ainda funcione. O usuário pode não ver
+    tudo o que costumava ver, e assim o comportamento é claramente
+    diferente, mas as coisas ainda _funcionam_, mesmo que possam não mostrar
+    mais informações sensíveis (ou não mais relevantes).
+
+Sobre regressões causadas por correções de bug
+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+
+* De `2018-08-03 <https://lore.kernel.org/all/CA+55aFwWZX=CXmWDTkDGb36kf12XmTehmQjbiMPCqCRG2hi9kw@mail.gmail.com/>`_::
+
+    > O kernel tinha um bug que foi corrigido
+
+    Isso é *COMPLETAMENTE* irrelevante.
+
+    Gente, se algo tinha bug ou não NÃO IMPORTA.
+
+    [...]
+
+    É basicamente dizer "peguei algo que funcionava, e eu o quebrei, mas
+    agora está melhor". Vocês não veem o quanto essa afirmação é insana?
+
+Sobre mudanças de API internas
+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+
+* De `2017-10-26(7) <https://lore.kernel.org/lkml/CA+55aFxW7NMAMvYhkvz1UPbUTUJewRt6Yb51QAx5RtrWOwjebg@mail.gmail.com/>`_::
+
+    Quebramos API _dentro_ do kernel o tempo todo. Corrigimos problemas
+    internos dizendo "agora você precisa fazer XYZ", mas então se trata de
+    APIs internas do kernel, e quem faz isso obviamente também tem de
+    consertar todos os usuários daquela API dentro do kernel. Ninguém pode
+    dizer "eu quebrei a API que você usava, e agora _você_ precisa
+    consertar". Quem quebrou algo também tem de consertar.
+
+Sobre regressões descobertas só depois de muito tempo
+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+
+* De `2024-03-28 <https://lore.kernel.org/all/CAHk-=wgFuoHpMk_Z_R3qMXVDgq0N1592+bABkyGjwwSL4zBtHA@mail.gmail.com/>`_::
+
+    Definitivamente não vou reverter um patch de quase uma década atrás
+    como regressão.
+
+    Se levou tanto tempo para descobrir, não pode ser uma regressão tão
+    crítica assim.
+
+    Então sim, vamos tratá-la como um bug comum.
+
+Sobre testar correções de regressão no linux-next
+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+
+* No `mantenedores summit 2024 <https://lwn.net/Articles/990599/>`_::
+
+   Então rodar correções pelo linux-next é só uma perda de tempo.
+
+Sobre alguns outros aspectos relacionados a regressões
+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+
+* De `2025-07-29(2)
+   <https://lore.kernel.org/all/CAHk-=wjj9DvOZtmTkoLtyfHmy5mNKy6q_96d9=4FUEDXre=cww@mail.gmail.com/>`_
+   [`que não é bem uma regressão, mas um enorme incômodo
+   <https://lore.kernel.org/all/CAHk-=wgO0Rx2LcYT4f75Xs46orbJ4JxO2jbAFQnVKDYAjV5HeQ@mail.gmail.com/>`_]::
+
+    Não tenho mais som.
+
+    Também suspeito que seja puramente porque "make oldconfig" não
+    funciona, e provavelmente desligou minhas configurações antigas do
+    Intel HDA. Ou algo assim.
+
+    Renomear parâmetros de configuração é *ruim*. Tenho batido na tecla
+    de que a fase Kconfig da compilação do kernel é provavelmente o
+    nosso ponto mais desagradável, e um ponto de dor real para quem se
+    envolve com o desenvolvimento, simplesmente porque compilar o
+    próprio kernel pode ser tão intimidador com centenas de perguntas
+    bastante esotéricas.
+
+..
+   fim-do-conteúdo
+..
+   Este texto está disponível sob GPL-2.0+ ou CC-BY-4.0, como declarado
+   no topo do arquivo. Se você quiser distribuir este texto apenas sob
+   CC-BY-4.0, use "The Linux kernel developers" como atribuição de
+   autoria e vincule isto como fonte:
+   https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/plain/Documentation/process/handling-regressions.rst
+..
+   Nota: apenas o conteúdo deste arquivo RST, como encontrado nas fontes
+   do kernel Linux, está disponível sob CC-BY-4.0, pois versões deste
+   texto que foram processadas (por exemplo, pelo sistema de compilação
+   do kernel) podem conter conteúdo retirado de arquivos que usam uma
+   licença mais restritiva.
diff --git a/Documentation/translations/pt_BR/process/index.rst b/Documentation/translations/pt_BR/process/index.rst
index d072f7e46767..805bb2607db5 100644
--- a/Documentation/translations/pt_BR/process/index.rst
+++ b/Documentation/translations/pt_BR/process/index.rst
@@ -46,6 +46,7 @@ devem estar familiarizados.
    Adicionando uma nova chamada de Sistema <adding-syscalls>
    Por que a classe de tipo "volatile" não deve ser usada <volatile-considered-harmful>
    Como não Deixar as ioctls malfeitas <botching-up-ioctls>
+   Lidando com regressões <handling-regressions>
 
 Guias de políticas e declarações de desenvolvedores
 ---------------------------------------------------

---
base-commit: 4405c18c95d2d0f99f6c581ef0ee8591a1aa6ccd
change-id: 20261122-handling-regressions-951a5b0c080d

Best regards,
--  
Eduardo Pereira Cruz <dreduardocruz@gmail.com>

