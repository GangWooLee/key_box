module ApplicationHelper
  # Lucide icon SVG paths (stroke-based, 24x24 viewBox)
  # Source: https://lucide.dev — MIT License
  LUCIDE_ICONS = {
    search: '<path d="m21 21-4.34-4.34" /><circle cx="11" cy="11" r="8" />',
    plus: '<path d="M5 12h14" /><path d="M12 5v14" />',
    folder: '<path d="M20 20a2 2 0 0 0 2-2V8a2 2 0 0 0-2-2h-7.9a2 2 0 0 1-1.69-.9L9.6 3.9A2 2 0 0 0 7.93 3H4a2 2 0 0 0-2 2v13a2 2 0 0 0 2 2Z" />',
    clipboard_copy: '<rect width="8" height="4" x="8" y="2" rx="1" ry="1" /><path d="M8 4H6a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-2" /><path d="M16 4h2a2 2 0 0 1 2 2v4" /><path d="M21 14H11" /><path d="m15 10-4 4 4 4" />',
    eye: '<path d="M2.062 12.348a1 1 0 0 1 0-.696 10.75 10.75 0 0 1 19.876 0 1 1 0 0 1 0 .696 10.75 10.75 0 0 1-19.876 0" /><circle cx="12" cy="12" r="3" />',
    eye_off: '<path d="M10.733 5.076a10.744 10.744 0 0 1 11.205 6.575 1 1 0 0 1 0 .696 10.747 10.747 0 0 1-1.444 2.49" /><path d="M14.084 14.158a3 3 0 0 1-4.242-4.242" /><path d="M17.479 17.499a10.75 10.75 0 0 1-15.417-5.151 1 1 0 0 1 0-.696 10.75 10.75 0 0 1 4.446-5.143" /><path d="m2 2 20 20" />',
    alert_triangle: '<path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 3.98 21h16.04a2 2 0 0 0 1.71-3Z" /><path d="M12 9v4" /><path d="M12 17h.01" />',
    pencil: '<path d="M21.174 6.812a1 1 0 0 0-3.986-3.987L3.842 16.174a2 2 0 0 0-.5.83l-1.321 4.352a.5.5 0 0 0 .623.622l4.353-1.32a2 2 0 0 0 .83-.497z" /><path d="m15 5 4 4" />',
    trash_2: '<path d="M3 6h18" /><path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6" /><path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2" /><line x1="10" x2="10" y1="11" y2="17" /><line x1="14" x2="14" y1="11" y2="17" />',
    arrow_left: '<path d="m12 19-7-7 7-7" /><path d="M19 12H5" />',
    key_round: '<path d="M2.586 17.414A2 2 0 0 0 2 18.828V21a1 1 0 0 0 1 1h3a1 1 0 0 0 1-1v-1a1 1 0 0 1 1-1h1a1 1 0 0 0 1-1v-1a1 1 0 0 1 1-1h.172a2 2 0 0 0 1.414-.586l.814-.814a6.5 6.5 0 1 0-4-4z" /><circle cx="16.5" cy="7.5" r=".5" fill="currentColor" />',
    clock: '<circle cx="12" cy="12" r="10" /><polyline points="12 6 12 12 16 14" />',
    lock: '<rect width="18" height="11" x="3" y="11" rx="2" ry="2" /><path d="M7 11V7a5 5 0 0 1 10 0v4" />',
    log_out: '<path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" /><polyline points="16 17 21 12 16 7" /><line x1="21" x2="9" y1="12" y2="12" />',
    sun: '<circle cx="12" cy="12" r="4" /><path d="M12 2v2" /><path d="M12 20v2" /><path d="m4.93 4.93 1.41 1.41" /><path d="m17.66 17.66 1.41 1.41" /><path d="M2 12h2" /><path d="M20 12h2" /><path d="m6.34 17.66-1.41 1.41" /><path d="m19.07 4.93-1.41 1.41" />',
    moon: '<path d="M12 3a6 6 0 0 0 9 9 9 9 0 1 1-9-9Z" />',
    command: '<path d="M15 6.5a2.5 2.5 0 1 0 5 0 2.5 2.5 0 1 0-5 0" /><path d="M4 6.5a2.5 2.5 0 1 0 5 0 2.5 2.5 0 1 0-5 0" /><path d="M15 17.5a2.5 2.5 0 1 0 5 0 2.5 2.5 0 1 0-5 0" /><path d="M4 17.5a2.5 2.5 0 1 0 5 0 2.5 2.5 0 1 0-5 0" /><path d="M9 6.5h6" /><path d="M9 17.5h6" /><path d="M6.5 9v6" /><path d="M17.5 9v6" />'
  }.freeze

  def lucide_icon(name, size: 4, css_class: nil, aria_label: nil, **options)
    paths = LUCIDE_ICONS[name.to_sym]
    return "" unless paths

    size_class = "size-#{size}"
    classes = [ size_class, css_class ].compact.join(" ")

    aria_attrs = if aria_label
      { role: "img", "aria-label": aria_label }
    else
      { "aria-hidden": "true" }
    end

    tag.svg(
      paths.html_safe,
      xmlns: "http://www.w3.org/2000/svg",
      viewBox: "0 0 24 24",
      fill: "none",
      stroke: "currentColor",
      "stroke-width": "2",
      "stroke-linecap": "round",
      "stroke-linejoin": "round",
      class: classes,
      **aria_attrs,
      **options
    )
  end

  # Service icon — initial letter with deterministic color circle
  SERVICE_COLORS = %w[
    bg-red-500 bg-orange-500 bg-amber-500 bg-emerald-500
    bg-cyan-500 bg-blue-500 bg-violet-500 bg-pink-500
  ].freeze

  def service_icon(service_name, size: 6)
    return "" unless service_name.present?

    color = service_icon_color(service_name)
    initial = service_name[0].upcase
    tag.span(
      initial,
      class: "inline-flex items-center justify-center size-#{size} rounded-full #{color} text-white text-xs font-semibold"
    )
  end

  def service_icon_color(service_name)
    SERVICE_COLORS[service_name.to_s.bytes.sum % SERVICE_COLORS.size]
  end

  # Environment badge (compact desktop style)
  ENVIRONMENT_STYLES = {
    "production"  => "bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-400",
    "staging"     => "bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-400",
    "development" => "bg-emerald-100 text-emerald-700 dark:bg-emerald-900/30 dark:text-emerald-400",
    "test"        => "bg-slate-100 text-slate-600 dark:bg-slate-800 dark:text-slate-400"
  }.freeze

  def environment_badge(env)
    return unless env.present?

    style = ENVIRONMENT_STYLES[env] || ENVIRONMENT_STYLES["test"]
    tag.span(
      env,
      class: "inline-flex items-center px-1.5 py-0.5 rounded-full text-[10px] font-medium #{style}"
    )
  end

  # Environment dot (for list items, even more compact)
  ENVIRONMENT_DOT_COLORS = {
    "production"  => "bg-red-400",
    "staging"     => "bg-amber-400",
    "development" => "bg-emerald-400",
    "test"        => "bg-slate-300"
  }.freeze

  def environment_dot(env)
    color = ENVIRONMENT_DOT_COLORS[env] || "bg-slate-300"
    tag.span(class: "inline-block size-1.5 rounded-full #{color}")
  end
end
