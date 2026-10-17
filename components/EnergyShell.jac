import from "@jac/runtime" { Link }

def:pub EnergyShell(current: str, children: any = None) -> JsxElement {
    has pointer_x: str = "52%";
    has pointer_y: str = "24%";

    def track_pointer(e: MouseEvent) {
        pointer_x = str(e.clientX) + "px";
        pointer_y = str(e.clientY) + "px";
    }

    return <main onMouseMove={track_pointer} className="relative min-h-svh overflow-hidden bg-[#090511] text-slate-100">
        <div className="pointer-events-none absolute inset-0 bg-[radial-gradient(ellipse_at_top_left,_#32105f_0%,_#170b2d_38%,_#090511_78%)]" />
        <div className="pointer-events-none absolute inset-0 opacity-70 transition-all duration-500" style={{"background": "radial-gradient(460px circle at " + pointer_x + " " + pointer_y + ", rgba(133,58,205,0.25), transparent 70%)"}} />
        <div className="relative mx-auto flex min-h-svh max-w-[1600px]">
            <aside className="hidden w-72 shrink-0 flex-col border-r border-white/10 bg-[#10091dcc] px-5 py-7 backdrop-blur-xl md:flex">
                <Link to="/" className="mb-10 flex items-center gap-3 rounded-xl px-2 py-2 transition-colors hover:bg-white/5">
                    <div className="relative flex size-12 items-center justify-center rounded-2xl border border-violet-300/30 bg-gradient-to-br from-violet-500/25 via-purple-500/15 to-cyan-400/20 shadow-lg shadow-violet-950/50">
                        <div className="absolute inset-2 rounded-full border border-cyan-300/70" />
                        <span className="relative text-xl font-black text-transparent bg-clip-text bg-gradient-to-br from-purple-300 to-cyan-300">V</span>
                    </div>
                    <div className="flex flex-col"><span className="text-lg font-bold tracking-[0.12em]">VOLT<span className="text-cyan-300">NEST</span></span><span className="text-[10px] font-medium tracking-[0.24em] text-violet-200/60">ENERGY PREDICTOR</span></div>
                </Link>
                <p className="mb-3 px-3 text-[10px] font-semibold uppercase tracking-[0.22em] text-violet-200/40">Workspace</p>
                <nav className="flex flex-col gap-2">
                    <Link to="/" className={"flex items-center gap-3 rounded-xl border px-3 py-3 text-sm transition-all duration-200 " + ("border-violet-300/25 bg-violet-500/15 text-white shadow-lg shadow-violet-950/20" if current == "home" else "border-transparent text-slate-400 hover:border-white/10 hover:bg-white/5 hover:text-white")}>
                        <span className="flex size-8 items-center justify-center rounded-lg bg-gradient-to-br from-violet-500/25 to-cyan-400/15 text-violet-200">⌂</span><span>Overview</span>
                    </Link>
                    <Link to="/simulator" className={"flex items-center gap-3 rounded-xl border px-3 py-3 text-sm transition-all duration-200 " + ("border-violet-300/25 bg-violet-500/15 text-white shadow-lg shadow-violet-950/20" if current == "simulator" else "border-transparent text-slate-400 hover:border-white/10 hover:bg-white/5 hover:text-white")}>
                        <span className="flex size-8 items-center justify-center rounded-lg bg-gradient-to-br from-violet-500/25 to-cyan-400/15 text-cyan-200">⌁</span><span>Energy predictor</span>
                    </Link>
                    <Link to="/circuits" className={"flex items-center gap-3 rounded-xl border px-3 py-3 text-sm transition-all duration-200 " + ("border-violet-300/25 bg-violet-500/15 text-white shadow-lg shadow-violet-950/20" if current == "circuits" else "border-transparent text-slate-400 hover:border-white/10 hover:bg-white/5 hover:text-white")}>
                        <span className="flex size-8 items-center justify-center rounded-lg bg-gradient-to-br from-violet-500/25 to-cyan-400/15 text-cyan-200">⌗</span><span>Circuit Designer</span>
                    </Link>
                    <Link to="/improve" className={"flex items-center gap-3 rounded-xl border px-3 py-3 text-sm transition-all duration-200 " + ("border-violet-300/25 bg-violet-500/15 text-white shadow-lg shadow-violet-950/20" if current == "improve" else "border-transparent text-slate-400 hover:border-white/10 hover:bg-white/5 hover:text-white")}>
                        <span className="flex size-8 items-center justify-center rounded-lg bg-gradient-to-br from-violet-500/25 to-cyan-400/15 text-cyan-200">+</span><span>Improve my home</span>
                    </Link>
                </nav>
                <div className="mt-auto rounded-2xl border border-violet-300/15 bg-gradient-to-br from-violet-500/10 to-cyan-400/5 p-4">
                    <div className="mb-2 flex items-center gap-2"><span className="size-2 rounded-full bg-cyan-300 shadow-[0_0_12px_#67e8f9]"/><span className="text-xs font-medium text-violet-100">Predict with confidence</span></div>
                    <p className="text-xs leading-relaxed text-slate-400">Explore your home's energy use with clear, practical estimates.</p>
                </div>
            </aside>
            <section className="min-w-0 flex-1">
                <header className="sticky top-0 z-20 flex h-16 items-center justify-between border-b border-white/10 bg-[#0d0718]/80 px-5 backdrop-blur-xl md:px-8">
                    <Link to="/" className="flex items-center gap-2 md:hidden"><span className="text-lg font-black tracking-[0.12em]">VOLT<span className="text-cyan-300">NEST</span></span></Link>
                    <p className="hidden text-xs font-medium uppercase tracking-[0.24em] text-violet-200/50 md:block">Home energy intelligence</p>
                    <div className="flex items-center gap-2 rounded-full border border-white/10 bg-white/5 px-3 py-1.5 text-xs text-slate-300"><span className="size-1.5 rounded-full bg-cyan-300 shadow-[0_0_10px_#67e8f9]"/>Ready</div>
                </header>
                <div className="border-b border-white/10 bg-[#10091d]/90 px-3 py-2 md:hidden">
                    <nav className="grid grid-cols-3 gap-2">
                        <Link to="/" className={"rounded-lg px-2 py-2 text-center text-xs " + ("bg-violet-500/20 text-white" if current == "home" else "text-slate-400")}>Overview</Link>
                        <Link to="/simulator" className={"rounded-lg px-2 py-2 text-center text-xs " + ("bg-violet-500/20 text-white" if current == "simulator" else "text-slate-400")}>Energy predictor</Link>
                        <Link to="/circuits" className={"rounded-lg px-2 py-2 text-center text-xs " + ("bg-violet-500/20 text-white" if current == "circuits" else "text-slate-400")}>Circuits</Link>
                    </nav>
                </div>
                <div className="relative animate-in fade-in slide-in-from-bottom-2 duration-500">{children}</div>
            </section>
        </div>
    </main>;
}
