import from .ui.card { Card, CardContent, CardHeader, CardTitle, CardDescription }

 def:pub VoltnestHome() -> JsxElement {
    return <main className="min-h-svh bg-muted/40 text-foreground">
        <header className="border-b bg-background/90">
            <div className="mx-auto flex h-16 max-w-6xl items-center gap-3 px-6">
                <div className="flex size-9 items-center justify-center rounded-xl bg-primary text-primary-foreground shadow-sm">
                    <span className="text-lg font-bold">V</span>
                </div>
                <span className="text-2xl font-bold tracking-tight">Voltnest</span>
                <span className="ml-auto hidden text-sm text-muted-foreground sm:block">Home circuit simulator</span>
            </div>
        </header>
        <section className="mx-auto grid max-w-6xl items-center gap-12 px-6 py-16 md:py-24 lg:grid-cols-2">
            <div className="flex flex-col items-start gap-6">
                <span className="rounded-full border bg-card px-3 py-1 text-sm text-muted-foreground">Made for curious homeowners</span>
                <h1 className="text-balance text-4xl font-semibold leading-[1.1] tracking-tight md:text-5xl">Voltnest home Circuit Simulator</h1>
                <p className="max-w-xl text-lg leading-relaxed text-muted-foreground">Explore how everyday home circuits fit together, explained in clear, simple words.</p>
                <div className="flex flex-wrap items-center gap-3">
                    <span className="rounded-lg bg-primary px-5 py-3 text-sm font-medium text-primary-foreground shadow-sm">Your workspace is ready</span>
                    <span className="text-sm text-muted-foreground">Start with the basics, at your own pace.</span>
                </div>
            </div>
            <Card className="relative overflow-hidden border-border/70 bg-card shadow-xl">
                <CardHeader className="border-b bg-background/60">
                    <div className="flex items-center gap-3">
                        <div className="flex size-10 items-center justify-center rounded-xl bg-primary/10 text-primary">
                            <span className="text-lg font-semibold">+</span>
                        </div>
                        <div>
                            <CardTitle>Home circuit</CardTitle>
                            <CardDescription>A simple view of how power travels</CardDescription>
                        </div>
                    </div>
                </CardHeader>
                <CardContent className="flex flex-col gap-5 p-6">
                    <div className="flex items-center justify-between gap-2">
                        <div className="rounded-xl border bg-background px-4 py-3 text-sm font-medium shadow-sm">Power source</div>
                        <div className="h-px flex-1 bg-primary/50" />
                        <div className="rounded-xl border bg-background px-4 py-3 text-sm font-medium shadow-sm">Light</div>
                    </div>
                    <div className="rounded-xl bg-muted/60 p-4 text-sm leading-relaxed text-muted-foreground">A circuit is a path that lets electricity travel from a power source to something useful, like a light.</div>
                    <div className="flex items-center gap-2 text-xs text-muted-foreground"><span className="size-2 rounded-full bg-primary" />Plain-language learning workspace</div>
                </CardContent>
            </Card>
        </section>
        <footer className="mx-auto max-w-6xl px-6 pb-8 text-xs text-muted-foreground">Learn home circuits with confidence.</footer>
    </main>;
}
