'use client';

export default function GlobalError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  return (
    <html>
      <body className="bg-slate-900 text-white">
        <div className="min-h-screen flex items-center justify-center">
          <div className="text-center p-8">
            <h2 className="text-2xl font-bold mb-4">Something went wrong!</h2>
            <button
              onClick={() => reset()}
              className="px-6 py-3 rounded-xl font-medium bg-emerald-500 text-white"
            >
              Try again
            </button>
          </div>
        </div>
      </body>
    </html>
  );
}
