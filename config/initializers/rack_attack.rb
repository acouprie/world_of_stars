class Rack::Attack
  # Login endpoint — 5 attempts per IP per minute
  throttle("logins/ip", limit: 5, period: 1.minute) do |req|
    req.ip if req.path == "/session" && req.post?
  end

  # Imperial advisor API — 1 call per player per minute (see architecture.md)
  throttle("advisor/user", limit: 1, period: 1.minute) do |req|
    req.env["warden"]&.user&.id if req.path.start_with?("/api/advisor")
  end

  # Block suspicious IPs after repeated 403/404s
  blocklist("block-brute-force") do |req|
    Rack::Attack::Allow2Ban.filter(req.ip, maxretry: 20, findtime: 1.minute, bantime: 1.hour) do
      req.env["rack.attack.matched"]
    end
  end
end
