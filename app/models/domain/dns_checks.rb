require "resolv"

class Domain

  def dns_ok?
    spf_status == "OK" && dkim_status == "OK" && ["OK", "Missing"].include?(mx_status) && ["OK", "Missing"].include?(return_path_status)
  end

  def dns_checked?
    spf_status.present?
  end

  def check_dns(source = :manual)
    check_spf_record
    check_dkim_record
    check_mx_records
    check_return_path_record
    self.dns_checked_at = Time.now
    save!
    if source == :auto && !dns_ok? && owner.is_a?(Server)
      WebhookRequest.trigger(owner, "DomainDNSError", {
        server: owner.webhook_hash,
        domain: name,
        uuid: uuid,
        dns_checked_at: dns_checked_at.to_f,
        spf_status: spf_status,
        spf_error: spf_error,
        dkim_status: dkim_status,
        dkim_error: dkim_error,
        mx_status: mx_status,
        mx_error: mx_error,
        return_path_status: return_path_status,
        return_path_error: return_path_error
      })
    end
    dns_ok?
  end

  #
  # SPF
  #

  def check_spf_record
    result = resolver.getresources(name, Resolv::DNS::Resource::IN::TXT)
    spf_records = result.map(&:data).select { |d| d =~ /\Av=spf1/ }
    if spf_records.empty?
      self.spf_status = "Missing"
      self.spf_error = "No SPF record exists for this domain"
    else
      suitable_spf_records = spf_records.select { |d| d =~ /include:\s*#{Regexp.escape(Postal.config.dns.spf_include)}/ }
      if suitable_spf_records.empty?
        self.spf_status = "Invalid"
        self.spf_error = "An SPF record exists but it doesn't include #{Postal.config.dns.spf_include}"
        false
      else
        self.spf_status = "OK"
        self.spf_error = nil
        true
      end
    end
  end

  def check_spf_record!
    check_spf_record
    save!
  end

  #
  # DKIM
  #

  def check_dkim_record
    domain = "#{dkim_record_name}.#{name}"
    result = resolver.getresources(domain, Resolv::DNS::Resource::IN::TXT)
    records = result.map(&:data)
    if records.empty?
      self.dkim_status = "Missing"
      self.dkim_error = "No TXT records were returned for #{domain}"
    else
      sanitised_dkim_record = records.first.strip.ends_with?(";") ? records.first.strip : "#{records.first.strip};"
      if records.size > 1
        self.dkim_status = "Invalid"
        self.dkim_error = "There are #{records.size} records for at #{domain}. There should only be one."
      elsif sanitised_dkim_record != dkim_record
        self.dkim_status = "Invalid"
        self.dkim_error = "The DKIM record at #{domain} does not match the record we have provided. Please check it has been copied correctly."
      else
        self.dkim_status = "OK"
        self.dkim_error = nil
        true
      end
    end
  end

  def check_dkim_record!
    check_dkim_record
    save!
  end

  #
  # MX
  #

  def check_mx_records
    result = resolver.getresources(name, Resolv::DNS::Resource::IN::MX)
    records = result.map(&:exchange)
    if records.empty?
      self.mx_status = "Missing"
      self.mx_error = "There are no MX records for #{name}"
    else
      missing_records = Postal.config.dns.mx_records.dup - records.map { |r| r.to_s.downcase }
      if missing_records.empty?
        self.mx_status = "OK"
        self.mx_error = nil
      elsif missing_records.size == Postal.config.dns.mx_records.size
        self.mx_status = "Missing"
        self.mx_error = "You have MX records but none of them point to us."
      else
        self.mx_status = "Invalid"
        self.mx_error = "MX #{missing_records.size == 1 ? 'record' : 'records'} for #{missing_records.to_sentence} are missing and are required."
      end
    end
  end

  def check_mx_records!
    check_mx_records
    save!
  end

  #
  # Return Path
  #

  def check_return_path_record
    result = resolver.getresources(return_path_domain, Resolv::DNS::Resource::IN::CNAME)
    records = result.map { |r| r.name.to_s.downcase }
    if records.empty?
      self.return_path_status = "Missing"
      self.return_path_error = "There is no return path record at #{return_path_domain}"
    else
      if records.size == 1 && records.first == Postal.config.dns.return_path
        self.return_path_status = "OK"
        self.return_path_error = nil
      else
        self.return_path_status = "Invalid"
        self.return_path_error = "There is a CNAME record at #{return_path_domain} but it points to #{records.first} which is incorrect. It should point to #{Postal.config.dns.return_path}."
      end
    end
  end

  def check_return_path_record!
    check_return_path_record
    save!
  end

end

# -*- SkipSchemaAnnotations
