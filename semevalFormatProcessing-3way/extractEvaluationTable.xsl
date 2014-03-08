<?xml version="1.0"?> 
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:output method="text"/>

<xsl:variable name="qid" select="/question/@id" />
<xsl:variable name="module" select="/question/@module" />
<xsl:variable name="testSet" select="/question/@testSet" />
<xsl:variable name='tab'><xsl:text>&#x09;</xsl:text></xsl:variable>
<xsl:variable name='newline'><xsl:text>
</xsl:text></xsl:variable>

<xsl:template match="node()|@*">
   <xsl:apply-templates select="@*|node()"/>	
</xsl:template>

<xsl:template match="studentAnswer">
  <xsl:value-of select="@id" />
  <xsl:value-of select="$tab" />
  <xsl:value-of select="$qid" />
  <xsl:value-of select="$tab" />
  <xsl:value-of select="$testSet" />
  <xsl:value-of select="$tab" />
  <xsl:value-of select="$module" />
  <xsl:value-of select="$tab" />
  <xsl:value-of select="@count" />
  <xsl:value-of select="$tab" />
  <xsl:value-of select="@accuracy" />
  <xsl:value-of select="$newline" />
</xsl:template>

</xsl:stylesheet>
