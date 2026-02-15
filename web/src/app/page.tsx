import Link from 'next/link';

export default function Home() {
  return (
    <div className="min-h-screen bg-[#1a1a2e] flex items-center justify-center">
      <div className="bg-[#16213e] p-8 rounded-2xl shadow-2xl max-w-md w-full mx-4 text-center">
        <h1 className="text-3xl font-bold text-white mb-4">
          🖥️ Browser Control
        </h1>
        <p className="text-gray-400 mb-6">
          Remote browser access with Google OAuth protection.
        </p>
        <Link
          href="/verify"
          className="inline-block bg-blue-600 hover:bg-blue-700 text-white font-semibold py-3 px-6 rounded-lg transition-colors"
        >
          Verify Your Email
        </Link>
        <p className="text-gray-500 text-sm mt-6">
          Part of the{' '}
          <a
            href="https://github.com/felipegoulu/browser-control"
            className="text-blue-400 hover:underline"
          >
            browser-control
          </a>{' '}
          skill for OpenClaw.
        </p>
      </div>
    </div>
  );
}
