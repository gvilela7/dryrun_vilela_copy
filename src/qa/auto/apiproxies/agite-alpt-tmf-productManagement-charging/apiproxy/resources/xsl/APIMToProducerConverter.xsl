<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output omit-xml-declaration="no" indent="yes" method="xml" version="1.0" encoding="UTF-8"/>
<xsl:strip-space elements="*"/>

<xsl:template match="/agreement/productPrice" xmlns:mii="http://www.ptinovacao.pt/qntintegration/mii">
  <id><xsl:value-of select="id"/></id>
  <spec_id><xsl:value-of select="specId"/></spec_id>
  <xsl:if test="status"><admin_status><xsl:value-of select="status"/></admin_status></xsl:if>
  <xsl:if test="validFor/startDateTime"><start_date><xsl:value-of select="validFor/startDateTime"/></start_date></xsl:if>
  <xsl:if test="validFor/endDateTime"><end_date><xsl:value-of select="validFor/endDateTime"/></end_date></xsl:if>
  <xsl:if test="scopeId"><scope_id><xsl:value-of select="scopeId"/></scope_id></xsl:if>
  <xsl:if test="operation"><operation><xsl:value-of select="operation"/></operation></xsl:if>
  <xsl:if test="productCharacteristic">
  <entries>
    <xsl:for-each select="productCharacteristic">
      <mii:entry>
        <key><xsl:value-of select="name"/></key>
        <value><xsl:value-of select="value"/></value>
      </mii:entry>
    </xsl:for-each>
  </entries>
  </xsl:if>
</xsl:template>


<xsl:template match="/">
<mii:agreement xmlns:mii="http://www.ptinovacao.pt/qntintegration/mii">
  <id><xsl:value-of select="agreement/id"/></id>
  <xsl:if test="agreement/productOffering/id"><product_offering_spec_id><xsl:value-of select="agreement/productOffering/id"/></product_offering_spec_id></xsl:if>
  <entries>
    <mii:entry>
      <key>status</key>
      <value><xsl:value-of select="agreement/status"/></value>
    </mii:entry>
    <xsl:if test="agreement/name">
    <mii:entry>
      <key>name</key>
      <value><xsl:value-of select="agreement/name"/></value>
    </mii:entry>
    </xsl:if>
    <xsl:if test="agreement/validFor/startDateTime">
    <mii:entry>
      <key>startDateTime</key>
      <value><xsl:value-of select="agreement/validFor/startDateTime"/></value>
    </mii:entry>
    </xsl:if>
    <xsl:if test="agreement/validFor/endDateTime">
    <mii:entry>
      <key>endDateTime</key>
      <value><xsl:value-of select="agreement/validFor/endDateTime"/></value>
    </mii:entry>
    </xsl:if>
    <xsl:if test="agreement/productOffering/name">
    <mii:entry>
      <key>productOfferingName</key>
      <value><xsl:value-of select="agreement/productOffering/name"/></value>
    </mii:entry>
    </xsl:if>
  </entries>
  <xsl:if test="agreement/productPrice[priceType='Usage Charge']">
  <usage_charges>
    <xsl:for-each select="agreement/productPrice[priceType='Usage Charge']">
      <mii:usage_charge>
        <xsl:apply-templates select="."/>
      </mii:usage_charge>
    </xsl:for-each>
  </usage_charges>
  </xsl:if>
  <xsl:if test="agreement/productPrice[priceType='Topup']">
  <topups>
    <xsl:for-each select="agreement/productPrice[priceType='Topup']">
      <mii:topup>
        <xsl:apply-templates select="."/>
      </mii:topup>
    </xsl:for-each>
  </topups>
  </xsl:if>
  <xsl:if test="agreement/productPrice[priceType='Allowance']">
  <allowances>
    <xsl:for-each select="agreement/productPrice[priceType='Allowance']">
      <mii:allowance>
        <xsl:apply-templates select="."/>
      </mii:allowance>
    </xsl:for-each>
  </allowances>
  </xsl:if>
  <xsl:if test="agreement/productPrice[priceType='Spending Limit']">
  <spending_limits>
    <xsl:for-each select="agreement/productPrice[priceType='Spending Limit']">
      <mii:spending_limit>
        <xsl:apply-templates select="."/>
      </mii:spending_limit>
    </xsl:for-each>
  </spending_limits>
  </xsl:if>
  <xsl:if test="agreement/productPrice[priceType='Alarm']">
  <alarms_ng>
    <xsl:for-each select="agreement/productPrice[priceType='Alarm']">
      <mii:alarm_ng>
        <xsl:apply-templates select="."/>
      </mii:alarm_ng>
    </xsl:for-each>
  </alarms_ng>
  </xsl:if>
  <xsl:if test="agreement/productPrice[priceType='Recurring Charge']">
  <recurring_charges>
    <xsl:for-each select="agreement/productPrice[priceType='Recurring Charge']">
      <mii:recurring_charge>
        <xsl:apply-templates select="."/>
      </mii:recurring_charge>
    </xsl:for-each>
  </recurring_charges>
  </xsl:if>
  <xsl:if test="agreement/productPrice[priceType='Balance Inquiry']">
  <balances>
    <xsl:for-each select="agreement/productPrice[priceType='Balance Inquiry']">
      <mii:balance>
        <xsl:apply-templates select="."/>
      </mii:balance>
    </xsl:for-each>
  </balances>
  </xsl:if>
  <xsl:if test="agreement/productPrice[priceType='One Time Allowance']">
  <otas>
    <xsl:for-each select="agreement/productPrice[priceType='One Time Allowance']">
      <mii:ota>
        <xsl:apply-templates select="."/>
      </mii:ota>
    </xsl:for-each>
  </otas>
  </xsl:if>
  <xsl:if test="agreement/productPrice[priceType='One Time Charge']">
  <otcs>
    <xsl:for-each select="agreement/productPrice[priceType='One Time Charge']">
      <mii:otc>
        <xsl:apply-templates select="."/>
      </mii:otc>
    </xsl:for-each>
  </otcs>
  </xsl:if>
</mii:agreement>
</xsl:template>

</xsl:stylesheet>