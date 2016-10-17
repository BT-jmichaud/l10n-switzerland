<?xml version='1.0' encoding='UTF-8'?>
<%block name="root">\
<Document xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="urn:iso:std:iso:20022:tech:xsd:pain.001.001.03">
</%block>\
\
  <CstmrCdtTrfInitn>
    <GrpHdr>
      <MsgId>${order.reference}</MsgId>
      <CreDtTm>${thetime.strftime("%Y-%m-%dT%H:%M:%S")}</CreDtTm>
      <NbOfTxs>${len (order.line_ids)}</NbOfTxs>
      <%
      control_sum = sum([line.amount_currency for line in order.line_ids])
      %>
      <CtrlSum>${control_sum}</CtrlSum>\
      <%block name="InitgPty">
        <InitgPty>
          <Nm>${order.user_id.company_id.name}</Nm>\
          ${address(order.user_id.company_id.partner_id)}\
        </InitgPty>\
      </%block>
    </GrpHdr>\
<%doc>\
  for each payment in the payment order
  line is saved in sepa_context in order to be available
  in sub blocks and inheritages. Because, for now, only unamed
  blocks and def in mako can use a local for loop variable.
</%doc>
<%
first_line = order.line_ids[0] if order.line_ids else None
today = thetime.strftime("%Y-%m-%d")
%>
<% sepa_context['line'] = first_line %>\
<%block name="PmtInf">\
<%
line = sepa_context['line']
today = thetime.strftime("%Y-%m-%d")
%>
<PmtInf>
    <PmtInfId>${line.name if line else ''}</PmtInfId>
    <PmtMtd>${order.mode.payment_method if order.mode else ''}</PmtMtd>
    <BtchBookg>${'true' if order.mode and order.mode.batchbooking else 'false'}</BtchBookg>
    <ReqdExctnDt>${(line.date > today and line.date or today) if line else ''}</ReqdExctnDt>
    <Dbtr>
      <Nm>${order.user_id.company_id.name}</Nm>\
      ${self.address(order.user_id.company_id.partner_id)}\
    </Dbtr>
    <DbtrAcct>\
      ${self.acc_id(order.mode.bank_id)}\
    </DbtrAcct>
    <DbtrAgt>
      <FinInstnId>
        <BIC>${order.mode.bank_id.bank.bic or order.mode.bank_id.bank_bic}</BIC>
      </FinInstnId>
    </DbtrAgt>
% for line in order.line_ids:

        <CdtTrfTxInf>
          <PmtId>
            <EndToEndId>${line.name}</EndToEndId>
          </PmtId>
          <%block name="PmtTpInf"/>
          <Amt>
            <InstdAmt Ccy="${line.currency.name}">${line.amount_currency}</InstdAmt>
          </Amt>
          <ChrgBr>SLEV</ChrgBr>

          <%block name="CdtrAgt">
            <%
            line=sepa_context['line']
            invoice = line.move_line_id.invoice
            %>
            <CdtrAgt>
              <FinInstnId>
                <BIC>${line.bank_id.bank.bic or line.bank_id.bank_bic}</BIC>
              </FinInstnId>
            </CdtrAgt>
          </%block>
          <Cdtr>
            <Nm>${line.partner_id.name}</Nm>\
            ${self.address(line.partner_id)}\
          </Cdtr>
          <CdtrAcct>\
            ${self.acc_id(line.bank_id)}\
          </CdtrAcct>\
          <%block name="RmtInf"/>
        </CdtTrfTxInf>

% endfor

</PmtInf>\
</%block>

\
  </CstmrCdtTrfInitn>
</Document>
\
<%def name="address(partner)">\
              <PstlAdr>
                %if partner.street:
                  <StrtNm>${partner.street}</StrtNm>
                %endif
                %if partner.zip:
                  <PstCd>${partner.zip}</PstCd>
                %endif
                %if partner.city:
                  <TwnNm>${partner.city}</TwnNm>
                %endif
                <Ctry>${partner.country_id.code or partner.company_id.country_id.code}</Ctry>
              </PstlAdr>
</%def>\
\
<%def name="acc_id(bank_acc)">
              <Id>
                % if bank_acc.state == 'iban':
                  <IBAN>${bank_acc.iban.replace(' ', '')}</IBAN>
                % else:
                  <Othr>
                    <Id>${bank_acc.acc_number}</Id>
                  </Othr>
                % endif
              </Id>
</%def>
